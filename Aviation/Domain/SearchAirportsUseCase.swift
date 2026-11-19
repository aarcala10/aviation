import Foundation

nonisolated struct SearchAirportsUseCase: Sendable {
    /// An IATA code has 3 letters; shorter queries would waste API quota.
    static let minimumLength = 3
    
    let repository: any AirportRepository
    
    func callAsFunction(_ query: String) async throws -> [Airport] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumLength else { return [] }
        return try await repository.airports(search: trimmed)
    }
}
