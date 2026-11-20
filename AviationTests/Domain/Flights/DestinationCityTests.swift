import Testing

@testable import Aviation

struct DestinationCityTests {
    private nonisolated struct FakeCities: CityLookup {
        func city(forIATA iata: String) -> String? { iata == "FCO" ? "Rome" : nil }
    }
    
    @Test("departures_fillsDestinationCity_andFallsBackToName")
    func departures_fillsDestinationCity_andFallsBackToName() async throws {
        let rome = Flight.sample(number: "AZ59")
        let unknown = Flight(
            number: "XX1", airline: "X", destinationIATA: "ZZZ", destinationName: "Zed Airport",
            scheduledTime: "06:10", reportedStatus: .scheduled, delayMinutes: 0,
            isCodeshare: false)
        let repo = MockFlightRepository { _ in [rome, unknown] }
        let flights = try await GetDeparturesUseCase(repository: repo, cities: FakeCities())(
            from: "MAD")
        #expect(flights.map(\.spokenDestination) == ["Rome", "Zed Airport"])
    }
    
    @Test("departures_withoutLookup_keepsTheApiName")
    func departures_withoutLookup_keepsTheApiName() async throws {
        let repo = MockFlightRepository { _ in [.sample()] }
        let flights = try await GetDeparturesUseCase(repository: repo)(from: "MAD")
        #expect(flights.first?.spokenDestination == "Leonardo Da Vinci (Fiumicino)")
    }
}
