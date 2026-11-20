import Testing

@testable import Aviation

struct FlightSectionTests {
    private func flight(_ number: String, date: String, time: String) -> Flight {
        Flight(
            number: number, airline: "X", destinationIATA: "FCO", destinationName: "Fiumicino",
            scheduledTime: time, reportedStatus: .scheduled, delayMinutes: 0, isCodeshare: false,
            date: date)
    }
    
    @Test("groupedByDate_newestDateFirst_earliestTimeFirstInside")
    func groupedByDate_newestDateFirst_earliestTimeFirstInside() {
        let sections = [
            flight("A", date: "2026-11-19", time: "23:00"),
            flight("B", date: "2026-11-20", time: "18:10"),
            flight("C", date: "2026-11-20", time: "05:55"),
            flight("D", date: "2026-11-19", time: "06:00"),
        ].groupedByDate()
        #expect(sections.map(\.date) == ["2026-11-20", "2026-11-19"])
        #expect(sections[0].flights.map(\.number) == ["C", "B"])
        #expect(sections[1].flights.map(\.number) == ["D", "A"])
    }
    
    @Test("groupedByDate_equalTimes_keepApiOrder")
    func groupedByDate_equalTimes_keepApiOrder() {
        let sections = [
            flight("A", date: "2026-11-20", time: "06:00"),
            flight("B", date: "2026-11-20", time: "06:00"),
            flight("C", date: "2026-11-20", time: "06:00"),
        ].groupedByDate()
        #expect(sections[0].flights.map(\.number) == ["A", "B", "C"])
    }
    
    @Test("groupedByDate_emptyDate_goesInTheLastSection")
    func groupedByDate_emptyDate_goesInTheLastSection() {
        let sections = [
            flight("A", date: "", time: "06:00"),
            flight("B", date: "2026-11-20", time: "07:00"),
        ].groupedByDate()
        #expect(sections.map(\.date) == ["2026-11-20", ""])
    }
    
    @Test("groupedByDate_noFlights_noSections")
    func groupedByDate_noFlights_noSections() {
        #expect([Flight]().groupedByDate().isEmpty)
    }
}
