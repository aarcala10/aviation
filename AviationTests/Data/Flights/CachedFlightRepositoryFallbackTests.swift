import Foundation
import SwiftData
import Testing

@testable import Aviation

struct CachedFlightRepositoryFallbackTests {
    @Test("wrapping_containerFails_usesRepositoryWithoutCache")
    func wrapping_containerFails_usesRepositoryWithoutCache() async throws {
        let mock = MockFlightRepository { _ in [.sample()] }
        let repo = CachedFlightRepository.wrapping(mock) { throw CocoaError(.fileReadUnknown) }
        _ = try await repo.departures(from: "MAD", limit: 100, offset: 0)
        _ = try await repo.departures(from: "MAD", limit: 100, offset: 0)
        #expect(await mock.calls.count == 2)
    }
    
    @Test("wrapping_containerOpens_caches")
    func wrapping_containerOpens_caches() async throws {
        let mock = MockFlightRepository { _ in [.sample()] }
        let repo = CachedFlightRepository.wrapping(mock) {
            try ModelContainer(
                for: CachedDepartures.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        _ = try await repo.departures(from: "MAD", limit: 100, offset: 0)
        _ = try await repo.departures(from: "MAD", limit: 100, offset: 0)
        #expect(await mock.calls.count == 1)
    }
}
