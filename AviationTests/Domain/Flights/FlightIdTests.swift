import Testing

@testable import Aviation

struct FlightIdTests {
    @Test("id_sameNumberDifferentTimeOrDate_isUnique")
    func id_sameNumberDifferentTimeOrDate_isUnique() {
        func flight(date: String, time: String) -> Flight {
            Flight(
                number: "AZ59", airline: "ITA Airways", destinationIATA: "FCO",
                destinationName: "Fiumicino", scheduledTime: time, reportedStatus: .scheduled,
                delayMinutes: 0, isCodeshare: false, date: date)
        }
        let ids = [
            flight(date: "2026-11-20", time: "05:55"), flight(date: "2026-11-20", time: "18:10"),
            flight(date: "2026-11-21", time: "05:55"),
        ].map(\.id)
        #expect(Set(ids).count == 3)
        #expect(flight(date: "2026-11-20", time: "05:55").id == ids[0])
    }
}
