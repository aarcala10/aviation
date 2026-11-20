nonisolated protocol AirportRepository: Sendable {
    func airports(search: String) async throws -> [Airport]
}
