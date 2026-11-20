nonisolated enum FlightStatus: String, Equatable, Sendable, Codable {
    case scheduled, active, landed, cancelled, incident, diverted, delayed, unknown
}

nonisolated struct Flight: Equatable, Sendable, Identifiable, Codable {
    let number: String
    let airline: String
    let destinationIATA: String
    let destinationName: String
    /// Departure time "HH:mm" in the airport's local time, as received.
    let scheduledTime: String
    let reportedStatus: FlightStatus
    let delayMinutes: Int
    let isCodeshare: Bool
    /// "yyyy-MM-dd", as received (`flight_date`).
    var date: String = ""
    /// City of the destination when known (filled by the use case), else empty.
    var destinationCity: String = ""
    /// What VoiceOver says for the destination: the city, or the API's airport name.
    var spokenDestination: String { destinationCity.isEmpty ? destinationName : destinationCity }
    /// A page can repeat a flight number on other days or at other times.
    var id: String { "\(number)-\(date)-\(scheduledTime)" }
    
    var status: FlightStatus {
        let canBeDelayed = reportedStatus == .scheduled || reportedStatus == .active
        return canBeDelayed && delayMinutes > 0 ? .delayed : reportedStatus
    }
}

nonisolated protocol FlightRepository: Sendable {
    func departures(from iata: String, limit: Int, offset: Int) async throws -> [Flight]
}
