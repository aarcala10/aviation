struct Airport: Equatable, Sendable, Identifiable {
    let name: String
    let iataCode: String
    let country: String
    var id: String { iataCode }
}

protocol AirportRepository: Sendable {
    func airports(search: String) async throws -> [Airport]
}
