struct GetDeparturesUseCase: Sendable {
    static let pageSize = 20
    
    let repository: any FlightRepository
    
    func callAsFunction(from iata: String) async throws -> [Flight] {
        try await repository.departures(from: iata, limit: Self.pageSize, offset: 0)
    }
}
