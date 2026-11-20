import Foundation
import SwiftData
import Testing
import os

@testable import Aviation

/// Controllable clock usable from a `@Sendable` closure.
private nonisolated final class TestClock: Sendable {
    private let time = OSAllocatedUnfairLock(initialState: Date(timeIntervalSince1970: 1_000_000))
    nonisolated var now: Date { time.withLock { $0 } }
    nonisolated func advance(_ seconds: TimeInterval) {
        time.withLock { $0 = $0.addingTimeInterval(seconds) }
    }
}

struct CachedFlightRepositoryTests {
    private let clock = TestClock()
    private let container: ModelContainer
    
    init() throws {
        container = try ModelContainer(
            for: CachedDepartures.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
    
    private func makeCache(_ mock: MockFlightRepository) -> CachedFlightRepository {
        let clock = clock
        return CachedFlightRepository(
            modelContainer: container, wrapping: mock, now: { clock.now })
    }
    
    @Test("flights_withinTTL_returnsCachedWithoutCallingRepository")
    func flights_withinTTL_returnsCachedWithoutCallingRepository() async throws {
        let mock = MockFlightRepository { _ in [.sample(number: "AZ59")] }
        let cache = makeCache(mock)
        let first = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        clock.advance(299)
        let second = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        #expect(second == first)
        #expect(await mock.calls.count == 1)
    }
    
    @Test("flights_afterTTL_callsRepositoryAgain")
    func flights_afterTTL_callsRepositoryAgain() async throws {
        let mock = MockFlightRepository { _ in [.sample()] }
        let cache = makeCache(mock)
        _ = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        clock.advance(CachedFlightRepository.ttl)
        _ = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        #expect(await mock.calls.count == 2)
    }
    
    @Test("flights_differentAirport_callsRepository")
    func flights_differentAirport_callsRepository() async throws {
        let mock = MockFlightRepository { _ in [.sample()] }
        let cache = makeCache(mock)
        _ = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        _ = try await cache.departures(from: "BCN", limit: 100, offset: 0)
        #expect(await mock.calls.map(\.iata) == ["MAD", "BCN"])
    }
    
    @Test("flights_differentPage_callsRepository")
    func flights_differentPage_callsRepository() async throws {
        let mock = MockFlightRepository { _ in [.sample()] }
        let cache = makeCache(mock)
        _ = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        _ = try await cache.departures(from: "MAD", limit: 100, offset: 100)
        #expect(await mock.calls.map(\.offset) == [0, 100])
    }
    
    @Test("flights_failure_isNotCached")
    func flights_failure_isNotCached() async throws {
        struct Boom: Error {}
        let attempts = OSAllocatedUnfairLock(initialState: 0)
        let mock = MockFlightRepository { _ in
            let attempt = attempts.withLock { n -> Int in
                n += 1
                return n
            }
            if attempt == 1 { throw Boom() }
            return [.sample()]
        }
        let cache = makeCache(mock)
        await #expect(throws: Boom.self) {
            try await cache.departures(from: "MAD", limit: 100, offset: 0)
        }
        let flights = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        #expect(flights == [.sample()])
        #expect(await mock.calls.count == 2)
    }
    
    @Test("flights_newRepositoryOnSameContainer_returnsCached")
    func flights_newRepositoryOnSameContainer_returnsCached() async throws {
        let mock = MockFlightRepository { _ in [.sample(number: "AZ59")] }
        let first = try await makeCache(mock).departures(from: "MAD", limit: 100, offset: 0)
        let second = try await makeCache(mock).departures(from: "MAD", limit: 100, offset: 0)
        #expect(second == first)
        #expect(await mock.calls.count == 1)
    }
    
    @Test("flights_afterTTL_replacesEntry")
    func flights_afterTTL_replacesEntry() async throws {
        let version = OSAllocatedUnfairLock(initialState: "OLD")
        let mock = MockFlightRepository { _ in [.sample(number: version.withLock { $0 })] }
        let cache = makeCache(mock)
        _ = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        clock.advance(CachedFlightRepository.ttl + 1)
        version.withLock { $0 = "NEW" }
        let refreshed = try await cache.departures(from: "MAD", limit: 100, offset: 0)
        #expect(refreshed.map(\.number) == ["NEW"])
        
        let entries = try ModelContext(container).fetch(FetchDescriptor<CachedDepartures>())
        #expect(entries.count == 1)
        let stored = try JSONDecoder().decode([Flight].self, from: #require(entries.first).flights)
        #expect(stored.map(\.number) == ["NEW"])
    }
}
