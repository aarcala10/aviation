import Foundation

actor AviationstackFlightRepository: FlightRepository {
    typealias Transport = @Sendable (URLRequest) async throws -> Data
    
    private struct Response: Decodable {
        let data: [Item]
    }
    
    private struct ErrorResponse: Decodable {
        let error: APIError
    }
    
    private struct Item: Decodable {
        struct Departure: Decodable {
            let scheduled: String
            let delay: Int?
        }
        struct Arrival: Decodable {
            let airport: String?
            let iata: String?
        }
        struct Airline: Decodable {
            let name: String?
        }
        struct Number: Decodable {
            let iata: String?
            let codeshared: Codeshared?
        }
        struct Codeshared: Decodable {}
        
        let flight_status: String?
        let departure: Departure
        let arrival: Arrival
        let airline: Airline?
        let flight: Number
    }
    
    let accessKey: String
    let transport: Transport
    
    init(accessKey: String, transport: @escaping Transport) {
        self.accessKey = accessKey
        self.transport = transport
    }
    
    /// A real `URLSession` transport.
    static func live(accessKey: String, session: URLSession = .shared)
        -> AviationstackFlightRepository
    {
        AviationstackFlightRepository(accessKey: accessKey) { request in
            try await session.data(for: request).0
        }
    }
    
    func departures(from iata: String, limit: Int, offset: Int) async throws -> [Flight] {
        var components = URLComponents(string: "https://api.aviationstack.com/v1/flights")!
        components.queryItems = [
            URLQueryItem(name: "access_key", value: accessKey),
            URLQueryItem(name: "dep_iata", value: iata),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        let data = try await transport(URLRequest(url: components.url!))
        let decoder = JSONDecoder()
        if let failure = try? decoder.decode(ErrorResponse.self, from: data) {
            throw failure.error
        }
        return try decoder.decode(Response.self, from: data).data.map { item in
            Flight(
                number: item.flight.iata ?? "",
                airline: item.airline?.name ?? "",
                destinationIATA: item.arrival.iata ?? "",
                destinationName: item.arrival.airport ?? "",
                scheduledTime: Self.localTime(item.departure.scheduled),
                reportedStatus: item.flight_status.flatMap(FlightStatus.init(rawValue:))
                    ?? .unknown,
                delayMinutes: item.departure.delay ?? 0,
                isCodeshare: item.flight.codeshared != nil)
        }
    }
    
    /// "2026-11-20T05:55:00+00:00" -> "05:55". The API sends the airport's local time with a fake
    /// +00:00 offset, so the text is used as received instead of converting it.
    private static func localTime(_ iso: String) -> String {
        guard let t = iso.firstIndex(of: "T") else { return "" }
        return String(iso[iso.index(after: t)...].prefix(5))
    }
}
