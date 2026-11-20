nonisolated struct Airport: Hashable, Sendable, Identifiable {
    let name: String
    let iataCode: String
    let country: String
    var id: String { iataCode }
}
