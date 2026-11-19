import Observation

@Observable
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
    
    func load() async {
        state = .loading
        do {
            let flights = try await getDepartures(from: airport.iataCode)
            guard !Task.isCancelled else { return }
            state = flights.isEmpty ? .empty : .loaded(flights)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(
                SearchViewModel.message(
                    for: error, generic: String(localized: "No se han podido cargar las salidas")))
        }
    }
}
