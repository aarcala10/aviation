nonisolated struct GetDeparturesUseCase: Sendable {
    static let pageSize = 100
    
    let repository: any FlightRepository
    
    /// Codeshares repeat the operated flight under other airlines, so only operated ones are kept.
    func callAsFunction(from iata: String) async throws -> [Flight] {
        try await repository.departures(from: iata, limit: Self.pageSize, offset: 0)
            .filter { !$0.isCodeshare }
    }
}
