import Foundation
import Testing

@testable import Aviation

struct AviationstackFlightDateTests {
    @Test("departures_mapsFlightDate")
    func departures_mapsFlightDate() async throws {
        let data = try Fixture.data("flights")
        let repo = AviationstackFlightRepository(accessKey: "KEY") { _ in data }
        let flights = try await repo.departures(from: "MAD", limit: 100, offset: 0)
        #expect(flights.map(\.date) == ["2026-11-20", "2026-11-20", "2026-11-20"])
    }
}
