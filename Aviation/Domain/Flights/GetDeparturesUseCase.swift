nonisolated struct DeparturesPage: Equatable, Sendable {
    let flights: [Flight]
    let nextOffset: Int?
}

nonisolated struct GetDeparturesUseCase: Sendable {
    static let pageSize = 100
    
    let repository: any FlightRepository
    var cities: (any CityLookup)?
    
    /// Codeshares repeat the operated flight under other airlines, so only operated ones are kept.
    func callAsFunction(from iata: String, offset: Int = 0) async throws -> DeparturesPage {
        let raw = try await repository.departures(from: iata, limit: Self.pageSize, offset: offset)
        let flights =
            raw
            .filter { !$0.isCodeshare }
            .map { flight in
                var flight = flight
                flight.destinationCity = city(forIATA: flight.destinationIATA) ?? ""
                flight.originCity = flight.originIATA.flatMap(city(forIATA:)) ?? ""
                return flight
            }
        return DeparturesPage(
            flights: flights, nextOffset: raw.count == Self.pageSize ? offset + Self.pageSize : nil)
    }
    
    func city(forIATA iata: String) -> String? { cities?.city(forIATA: iata) }
}
