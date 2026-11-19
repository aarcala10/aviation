import Observation

@MainActor @Observable
final class FlightsViewModel {
    enum State: Equatable {
        case idle, loading
        case loaded([Flight])
        case empty
        case failed(String)
    }
    
    private(set) var state: State = .idle
    let airport: Airport
    private let getDepartures: GetDeparturesUseCase
    
    init(airport: Airport, getDepartures: GetDeparturesUseCase) {
        self.airport = airport
        self.getDepartures = getDepartures
    }
    
    func load() async {}
}
