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
    
    /// Counts started loads: a stale (cancelled or replaced) load must never write state.
    @ObservationIgnored private var generation = 0
    
    /// False when a newer load started (leave its state alone) or this one was cancelled
    /// (nothing newer exists, so do not leave `.loading` behind).
    private func isCurrent(_ mine: Int) -> Bool {
        guard mine == generation else { return false }
        guard !Task.isCancelled else {
            state = .idle
            return false
        }
        return true
    }
    
    func load() async {
        generation += 1
        let mine = generation
        state = .loading
        do {
            let flights = try await getDepartures(from: airport.iataCode)
            guard isCurrent(mine) else { return }
            state = flights.isEmpty ? .empty : .loaded(flights)
        } catch {
            guard isCurrent(mine) else { return }
            state = .failed(
                SearchViewModel.message(
                    for: error, generic: String(localized: "No se han podido cargar las salidas")))
        }
    }
}
