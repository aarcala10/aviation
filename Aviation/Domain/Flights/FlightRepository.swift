nonisolated protocol FlightRepository: Sendable {
    func departures(from iata: String, limit: Int, offset: Int) async throws -> [Flight]
}
