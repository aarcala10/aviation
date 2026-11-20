import Testing

@testable import Aviation

struct FlightsSectionsTests {
    @Test("sections_loaded_groupsByDateNewestFirst")
    func sections_loaded_groupsByDateNewestFirst() async {
        let old = Flight(
            number: "OLD", airline: "X", destinationIATA: "FCO", destinationName: "F",
            scheduledTime: "06:00", reportedStatus: .scheduled, delayMinutes: 0,
            isCodeshare: false, date: "2026-11-19")
        let new = Flight(
            number: "NEW", airline: "X", destinationIATA: "FCO", destinationName: "F",
            scheduledTime: "06:00", reportedStatus: .scheduled, delayMinutes: 0,
            isCodeshare: false, date: "2026-11-20")
        let vm = FlightsViewModel(
            airport: .madrid,
            getDepartures: GetDeparturesUseCase(
                repository: MockFlightRepository { _ in [old, new] }))
        #expect(vm.sections.isEmpty)
        await vm.load()
        #expect(vm.sections.map(\.date) == ["2026-11-20", "2026-11-19"])
        #expect(vm.sections.map { $0.flights.map(\.number) } == [["NEW"], ["OLD"]])
    }
}
