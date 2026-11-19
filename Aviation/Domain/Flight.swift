enum FlightStatus: String, Equatable, Sendable {
    case scheduled, active, landed, cancelled, incident, diverted, delayed, unknown
}

struct Flight: Equatable, Sendable, Identifiable {
    let number: String
    let airline: String
    let destinationIATA: String
    let destinationName: String
    /// Departure time "HH:mm" in the airport's local time, as received.
    let scheduledTime: String
    let reportedStatus: FlightStatus
    let delayMinutes: Int
    let isCodeshare: Bool
    var id: String { number }
    
    var status: FlightStatus {
        let canBeDelayed = reportedStatus == .scheduled || reportedStatus == .active
        return canBeDelayed && delayMinutes > 0 ? .delayed : reportedStatus
    }
}

protocol FlightRepository: Sendable {
    func departures(from iata: String, limit: Int, offset: Int) async throws -> [Flight]
}
