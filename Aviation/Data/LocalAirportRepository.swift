import Foundation

/// Searches a bundled airport list (JSON array of {n, c, i, k}).
struct LocalAirportRepository: AirportRepository {
    // RED stub.
    init(data: Data) throws {}
    
    func airports(search: String) async throws -> [Airport] { [] }
}
