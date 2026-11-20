import Testing

@testable import Aviation

struct FlightDetailDomainTests {
    private nonisolated struct FakeCities: CityLookup {
        func city(forIATA iata: String) -> String? { iata == "MAD" ? "Madrid" : nil }
    }
    
    @Test("departures_fillsOriginCity")
    func departures_fillsOriginCity() async throws {
        var sample = Flight.sample()
        sample.originIATA = "MAD"
        let flight = sample
        let repo = MockFlightRepository { _ in [flight] }
        let flights = try await GetDeparturesUseCase(repository: repo, cities: FakeCities())(
            from: "MAD")
        #expect(flights.first?.originCity == "Madrid")
    }
    
    @Test("landedLate_withArrivalDelay_isTrue")
    func landedLate_withArrivalDelay_isTrue() {
        var flight = Flight.sample(status: .landed)
        flight.arrivalDelayMinutes = 12
        #expect(flight.landedLate)
    }
    
    @Test("landedLate_withoutArrivalDelay_isFalse")
    func landedLate_withoutArrivalDelay_isFalse() {
        var flight = Flight.sample(status: .landed)
        #expect(!flight.landedLate)
        flight.arrivalDelayMinutes = 0
        #expect(!flight.landedLate)
    }
}
