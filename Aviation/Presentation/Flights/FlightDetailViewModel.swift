/// Read-only projection of a flight: no mutable state, so no `@Observable`.
final class FlightDetailViewModel {
    let flight: Flight
    
    init(flight: Flight) { self.flight = flight }
    
    /// Shown for a missing value; the view speaks it as "Sin dato".
    static let dash = "—"
    
    private static func text(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return dash }
        return value
    }
    
    private static func delay(_ minutes: Int?) -> String {
        guard let minutes, minutes > 0 else { return dash }
        return String(localized: "\(minutes) min")
    }
    
    var originCode: String { Self.text(flight.originIATA) }
    var destinationCode: String { flight.destinationIATA }
    var status: FlightStatus { flight.status }
    
    var departureTerminal: String { Self.text(flight.departureTerminal) }
    var departureGate: String { Self.text(flight.departureGate) }
    var departureScheduled: String { Self.text(flight.scheduledTime) }
    var departureEstimated: String { Self.text(flight.estimatedTime) }
    var departureDelay: String { Self.delay(flight.delayMinutes) }
    
    var arrivalTerminal: String { Self.text(flight.arrivalTerminal) }
    var arrivalGate: String { Self.text(flight.arrivalGate) }
    var arrivalScheduled: String { Self.text(flight.arrivalScheduledTime) }
    var arrivalEstimated: String { Self.text(flight.arrivalEstimatedTime) }
    var arrivalDelay: String { Self.delay(flight.arrivalDelayMinutes) }
    
    var airline: String { flight.airline }
    var number: String { flight.number }
    var date: String { FlightDate.title(flight.date) }
    
    /// What VoiceOver reads for the header: the city, else the airport name, else the code.
    var spokenHeader: String {
        let number = flight.number.map(String.init).joined(separator: " ")
        let origin =
            [flight.originCity, flight.originName ?? "", flight.originIATA ?? ""]
            .first { !$0.isEmpty } ?? ""
        let destination =
            [flight.spokenDestination, flight.destinationIATA]
            .first { !$0.isEmpty } ?? ""
        let status = StatusBadge(status: flight.status, landedLate: flight.landedLate)
            .spokenTitle
        return String(localized: "Vuelo \(number). De \(origin) a \(destination). \(status).")
    }
}
