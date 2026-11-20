import Foundation
import Testing

@testable import Aviation

struct AviationstackMalformedItemTests {
    private func item(_ number: String, scheduled: String) -> String {
        """
        {"flight_date":"2026-11-20","flight_status":"scheduled",
         "departure":{"scheduled":\(scheduled),"delay":0},
         "arrival":{"airport":"Fiumicino","iata":"FCO"},
         "airline":{"name":"ITA Airways"},
         "flight":{"iata":"\(number)","codeshared":null}}
        """
    }
    
    @Test("departures_malformedItem_isDroppedAndTheRestKept")
    func departures_malformedItem_isDroppedAndTheRestKept() async throws {
        let json = """
            {"data":[\(item("AZ1", scheduled: "\"2026-11-20T05:55:00+00:00\"")),
                     \(item("AZ2", scheduled: "null")),
                     {"flight_date":"2026-11-20"},
                     \(item("AZ3", scheduled: "\"2026-11-20T06:10:00+00:00\""))]}
            """
        let data = Data(json.utf8)
        let repo = AviationstackFlightRepository(accessKey: "KEY") { _ in data }
        let flights = try await repo.departures(from: "MAD", limit: 100, offset: 0)
        #expect(flights.map(\.number) == ["AZ1", "AZ3"])
    }
}
