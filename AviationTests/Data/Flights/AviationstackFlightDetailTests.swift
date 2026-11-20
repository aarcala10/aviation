import Foundation
import Testing

@testable import Aviation

struct AviationstackFlightDetailTests {
    private func flights() async throws -> [Flight] {
        let data = try Fixture.data("flights")
        let repo = AviationstackFlightRepository(accessKey: "KEY") { _ in data }
        return try await repo.departures(from: "MAD", limit: 20, offset: 0)
    }
    
    @Test("departures_decodesDepartureDetails")
    func departures_decodesDepartureDetails() async throws {
        let operated = try #require(await flights().last)
        #expect(operated.originIATA == "MAD")
        #expect(operated.originName == "Barajas")
        #expect(operated.departureTerminal == "1")
        #expect(operated.departureGate == "B12")
        #expect(operated.estimatedTime == "06:35")
    }
    
    @Test("departures_decodesArrivalDetails")
    func departures_decodesArrivalDetails() async throws {
        let operated = try #require(await flights().last)
        #expect(operated.arrivalTerminal == "1")
        #expect(operated.arrivalScheduledTime == "08:30")
        #expect(operated.arrivalEstimatedTime == "08:55")
        #expect(operated.arrivalDelayMinutes == 25)
    }
    
    @Test("departures_missingDetails_areNil")
    func departures_missingDetails_areNil() async throws {
        let all = try await flights()
        let first = try #require(all.first)
        #expect(first.departureGate == nil)
        #expect(first.arrivalGate == nil)
        #expect(first.arrivalEstimatedTime == nil)
        #expect(first.arrivalDelayMinutes == nil)
        #expect(try #require(all.last).arrivalGate == nil)
    }
}
