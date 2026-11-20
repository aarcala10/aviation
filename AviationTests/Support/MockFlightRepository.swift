@testable import Aviation

actor MockFlightRepository: FlightRepository {
    struct Call: Equatable {
        let iata: String
        let limit: Int
        let offset: Int
    }
    
    private(set) var calls: [Call] = []
    private let handler: @Sendable (Call) async throws -> [Flight]
    
    init(handler: @escaping @Sendable (Call) async throws -> [Flight] = { _ in [] }) {
        self.handler = handler
    }
    
    func departures(from iata: String, limit: Int, offset: Int) async throws -> [Flight] {
        let call = Call(iata: iata, limit: limit, offset: offset)
        calls.append(call)
        return try await handler(call)
    }
}

extension Flight {
    nonisolated static func sample(
        number: String = "AZ59", status: FlightStatus = .scheduled, delay: Int = 0,
        isCodeshare: Bool = false
    ) -> Flight {
        Flight(
            number: number, airline: "ITA Airways", destinationIATA: "FCO",
            destinationName: "Leonardo Da Vinci (Fiumicino)", scheduledTime: "05:55",
            reportedStatus: status, delayMinutes: delay, isCodeshare: isCodeshare)
    }
}
