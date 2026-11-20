import Testing

@testable import Aviation

struct FlightsSpokenCityTests {
    private nonisolated struct FakeCities: CityLookup {
        func city(forIATA iata: String) -> String? { iata == "MAD" ? "Madrid" : nil }
    }
    
    private func makeVM(_ airport: Airport, cities: (any CityLookup)?) -> FlightsViewModel {
        FlightsViewModel(
            airport: airport,
            getDepartures: GetDeparturesUseCase(repository: MockFlightRepository(), cities: cities))
    }
    
    @Test("spokenCity_usesCity_thenAirportName")
    func spokenCity_usesCity_thenAirportName() {
        #expect(makeVM(.madrid, cities: FakeCities()).spokenCity == "Madrid")
        #expect(makeVM(.barcelona, cities: FakeCities()).spokenCity == "Barcelona El Prat")
        #expect(makeVM(.madrid, cities: nil).spokenCity == "Adolfo Suarez Madrid-Barajas")
    }
}
