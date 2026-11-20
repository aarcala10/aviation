import Foundation

/// Searches a bundled airport list (JSON array of {n: name, c: city, i: IATA, k: ISO country}).
nonisolated struct LocalAirportRepository: AirportRepository, CityLookup {
    /// IATA (uppercased) -> city, built once; airports without a city are left out.
    private let cityByIATA: [String: String]
    
    func city(forIATA iata: String) -> String? { cityByIATA[iata.uppercased()] }
    
    /// A 3-letter query can match hundreds of airports; the list only needs the best ones.
    private static let maxResults = 50
    
    private nonisolated struct Record: Decodable, Sendable {
        let n: String, c: String, i: String, k: String
    }
    
    private let records: [Record]
    
    init(data: Data) throws {
        records = try JSONDecoder().decode([Record].self, from: data)
        cityByIATA = Dictionary(
            records.filter { !$0.c.isEmpty }.map { ($0.i.uppercased(), $0.c) },
            uniquingKeysWith: { first, _ in first })
    }
    
    // Off the caller's (main) actor: async functions otherwise run on the caller's actor.
    @concurrent
    func airports(search: String) async throws -> [Airport] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let matches = records.filter { record in
            [record.n, record.c, record.i].contains { $0.range(of: query, options: options) != nil }
        }
        let exactCode = matches.filter { $0.i.caseInsensitiveCompare(query) == .orderedSame }
        let others = matches.filter { $0.i.caseInsensitiveCompare(query) != .orderedSame }
        let spanish = Locale(identifier: "es")
        return (exactCode + others).prefix(Self.maxResults).map {
            Airport(
                name: $0.n, iataCode: $0.i,
                country: spanish.localizedString(forRegionCode: $0.k) ?? $0.k)
        }
    }
}
