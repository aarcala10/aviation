import Foundation

/// Body aviationstack returns on failure (HTTP 200 or 4xx).
struct APIError: Error, Equatable, Sendable, Decodable {
    let code: String
    let message: String
}

struct AviationstackClient: AirportRepository {
    var baseURL = URL(string: "http://api.aviationstack.com/v1")!
    let accessKey: String
    var session: URLSession = .shared
    
    private struct Response: Decodable {
        struct Item: Decodable {
            let airport_name: String
            let iata_code: String?
            let country_name: String?
        }
        let data: [Item]?
        let error: APIError?
    }
    
    func airports(search: String) async throws -> [Airport] {
        let url = baseURL.appending(path: "airports").appending(queryItems: [
            URLQueryItem(name: "access_key", value: accessKey),
            URLQueryItem(name: "search", value: search),
        ])
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(Response.self, from: data)
        if let error = response.error { throw error }
        return (response.data ?? []).compactMap { item in
            item.iata_code.map {
                Airport(name: item.airport_name, iataCode: $0, country: item.country_name ?? "")
            }
        }
    }
}
