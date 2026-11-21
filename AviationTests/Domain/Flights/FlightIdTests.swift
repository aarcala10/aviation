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
    
    @Test("id_sameNumberAndTime_differentAirlineOrDestination_isUnique")
    func id_sameNumberAndTime_differentAirlineOrDestination_isUnique() {
        func flight(number: String, airline: String, to iata: String) -> Flight {
            Flight(
                number: number, airline: airline, destinationIATA: iata, destinationName: "",
                scheduledTime: "05:55", reportedStatus: .scheduled, delayMinutes: 0,
                isCodeshare: false, date: "2026-11-20")
        }
        let ids = [
            flight(number: "ES894", airline: "Iberojet", to: "PUJ"),
            flight(number: "ES894", airline: "DHL", to: "PUJ"),
            flight(number: "", airline: "Iberia", to: "OVD"),
            flight(number: "", airline: "Iberia", to: "LEI"),
        ].map(\.id)
        #expect(Set(ids).count == 4)
    }
}
