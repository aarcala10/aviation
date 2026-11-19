import Foundation

/// Body aviationstack returns on failure (HTTP 200 or 4xx).
struct APIError: Error, Equatable, Sendable {
    let code: String
    let message: String
}

struct AviationstackClient: AirportRepository {
    var baseURL = URL(string: "http://api.aviationstack.com/v1")!
    let accessKey: String
    var session: URLSession = .shared
    
    // RED stub.
    func airports(search: String) async throws -> [Airport] {
        throw URLError(.unknown)
    }
}
