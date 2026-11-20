import Observation

@Observable
final class FlightDetailViewModel {
    let flight: Flight
    
    init(flight: Flight) { self.flight = flight }
    
    var originCode: String { "" }
    var destinationCode: String { "" }
    var status: FlightStatus { .unknown }
    
    var departureTerminal: String { "" }
    var departureGate: String { "" }
    var departureScheduled: String { "" }
    var departureEstimated: String { "" }
    var departureDelay: String { "" }
    
    var arrivalTerminal: String { "" }
    var arrivalGate: String { "" }
    var arrivalScheduled: String { "" }
    var arrivalEstimated: String { "" }
    var arrivalDelay: String { "" }
    
    var airline: String { "" }
    var number: String { "" }
    var date: String { "" }
    
    /// What VoiceOver reads for the header.
    var spokenHeader: String { "" }
}
