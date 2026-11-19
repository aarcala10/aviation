import Foundation

struct AviationstackFlightRepository: FlightRepository {
    typealias Transport = @Sendable (URLRequest) async throws -> Data
    
    let accessKey: String
    let transport: Transport
    
    func departures(from iata: String, limit: Int, offset: Int) async throws -> [Flight] {
        []
    }
}
