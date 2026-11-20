import Foundation

nonisolated struct AviationstackFlightRepository: FlightRepository {
    typealias Transport = @Sendable (URLRequest) async throws -> Data
    
    private nonisolated struct Response: Decodable {
        let data: [Lenient]
    }
    
    /// One unreadable item must not discard the rest of the page: it decodes to nil and is dropped.
    private nonisolated struct Lenient: Decodable {
        let item: Item?
        init(from decoder: Decoder) throws {
            item = try? Item(from: decoder)
        }
    }
    
    private nonisolated struct ErrorResponse: Decodable {
        let error: APIError
    }
    
    private nonisolated struct Item: Decodable {
        nonisolated struct Departure: Decodable {
            let airport: String?
            let iata: String?
            let terminal: String?
            let gate: String?
            let scheduled: String
            let estimated: String?
            let delay: Int?
        }
        nonisolated struct Arrival: Decodable {
            let airport: String?
            let iata: String?
            let terminal: String?
            let gate: String?
            let scheduled: String?
            let estimated: String?
            let delay: Int?
        }
        nonisolated struct Airline: Decodable {
            let name: String?
        }
        nonisolated struct Number: Decodable {
            let iata: String?
            let codeshared: Codeshared?
        }
        nonisolated struct Codeshared: Decodable {}
        
        let flight_date: String?
        let flight_status: String?
        let departure: Departure
        let arrival: Arrival
        let airline: Airline?
        let flight: Number
    }
    
    let accessKey: String
    let transport: Transport
    
    static func live(accessKey: String, session: URLSession = .shared)
        -> AviationstackFlightRepository
    {
        AviationstackFlightRepository(accessKey: accessKey) { request in
            try await session.data(for: request).0
        }
    }
    
    // Off the main actor even if NonisolatedNonsendingByDefault is turned on.
    @concurrent
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
        return try decoder.decode(Response.self, from: data).data.compactMap(\.item).map { item in
            Flight(
                number: item.flight.iata ?? "",
                airline: item.airline?.name ?? "",
                destinationIATA: item.arrival.iata ?? "",
                destinationName: item.arrival.airport ?? "",
                scheduledTime: Self.localTime(item.departure.scheduled),
                reportedStatus: item.flight_status.flatMap(FlightStatus.init(rawValue:))
                    ?? .unknown,
                delayMinutes: item.departure.delay ?? 0,
                isCodeshare: item.flight.codeshared != nil,
                date: item.flight_date ?? "",
                originIATA: item.departure.iata,
                originName: item.departure.airport,
                departureTerminal: item.departure.terminal,
                departureGate: item.departure.gate,
                estimatedTime: item.departure.estimated.map(Self.localTime),
                arrivalTerminal: item.arrival.terminal,
                arrivalGate: item.arrival.gate,
                arrivalScheduledTime: item.arrival.scheduled.map(Self.localTime),
                arrivalEstimatedTime: item.arrival.estimated.map(Self.localTime),
                arrivalDelayMinutes: item.arrival.delay)
        }
    }
    
    /// "2026-11-20T05:55:00+00:00" -> "05:55". The API sends the airport's local time with a fake
    /// +00:00 offset, so the text is used as received instead of converting it.
    private static func localTime(_ iso: String) -> String {
        guard let t = iso.firstIndex(of: "T") else { return "" }
        return String(iso[iso.index(after: t)...].prefix(5))
    }
}
