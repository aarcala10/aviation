nonisolated enum FlightStatus: String, Equatable, Sendable, Codable {
    case scheduled, active, landed, cancelled, incident, diverted, delayed, unknown
}

nonisolated struct Flight: Equatable, Sendable, Hashable, Identifiable, Codable {
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
    // Detail fields: optional so a page already in the cache still decodes. Times are "HH:mm" local.
    var originIATA: String? = nil
    var originName: String? = nil
    var originCity: String = ""
    var departureTerminal: String? = nil
    var departureGate: String? = nil
    var estimatedTime: String? = nil
    var arrivalTerminal: String? = nil
    var arrivalGate: String? = nil
    var arrivalScheduledTime: String? = nil
    var arrivalEstimatedTime: String? = nil
    var arrivalDelayMinutes: Int? = nil
    var landedLate: Bool { reportedStatus == .landed && (arrivalDelayMinutes ?? 0) > 0 }
    /// What VoiceOver says for the destination: the city, or the API's airport name.
    var spokenDestination: String { destinationCity.isEmpty ? destinationName : destinationCity }
    /// A page can repeat a flight number on other days or at other times.
    var id: String { "\(number)-\(date)-\(scheduledTime)" }
    
    var status: FlightStatus {
        let canBeDelayed = reportedStatus == .scheduled || reportedStatus == .active
        return canBeDelayed && delayMinutes > 0 ? .delayed : reportedStatus
    }
}
