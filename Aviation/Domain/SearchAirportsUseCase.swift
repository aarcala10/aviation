struct SearchAirportsUseCase: Sendable {
    let repository: any AirportRepository
    
    // RED stub: no trimming, no minimum length, swallows errors.
    func callAsFunction(_ query: String) async throws -> [Airport] {
        _ = try? await repository.airports(search: query)
        return []
    }
}
