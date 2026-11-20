import Observation

@Observable
final class FlightsViewModel {
    enum State: Equatable {
        case idle, loading
        case loaded([Flight])
        case empty
        case failed(String)
    }
    
    enum More: Equatable {
        case available, loading
        case failed(String)
        case complete
    }
    
    private(set) var state: State = .idle
    private(set) var more: More = .complete
    @ObservationIgnored private var nextOffset: Int?
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
    
    /// What VoiceOver says in the heading: the city, or the airport name when the city is unknown.
    var spokenCity: String { getDepartures.city(forIATA: airport.iataCode) ?? airport.name }
    
    /// The loaded flights grouped by date, newest day first.
    var sections: [FlightSection] {
        guard case .loaded(let flights) = state else { return [] }
        return flights.groupedByDate()
    }
    
    /// Appends the next page. A `load()` started meanwhile invalidates it through `generation`.
    func loadMore() async {
        switch more {
        case .available, .failed: break
        case .loading, .complete: return
        }
        guard case .loaded(var shown) = state, var offset = nextOffset else { return }
        let mine = generation
        more = .loading
        do {
            var known = Set(shown.map(\.id))
            var added = false
            // A page of only codeshares or repeats adds nothing: keep going so the list can grow.
            while !added {
                let page = try await getDepartures(from: airport.iataCode, offset: offset)
                guard mine == generation else { return }
                let fresh = page.flights.filter { known.insert($0.id).inserted }
                shown += fresh
                added = !fresh.isEmpty
                nextOffset = page.nextOffset
                guard let next = page.nextOffset else { break }
                offset = next
            }
            state = .loaded(shown)
            more = nextOffset == nil ? .complete : .available
        } catch {
            guard mine == generation else { return }
            more = .failed(
                SearchViewModel.message(
                    for: error, generic: String(localized: "No se han podido cargar más salidas")))
        }
    }
    
    func load() async {
        generation += 1
        let mine = generation
        state = .loading
        more = .complete
        nextOffset = nil
        do {
            let page = try await getDepartures(from: airport.iataCode)
            guard isCurrent(mine) else { return }
            state = page.flights.isEmpty ? .empty : .loaded(page.flights)
            nextOffset = page.nextOffset
            more = page.nextOffset == nil ? .complete : .available
        } catch {
            guard isCurrent(mine) else { return }
            state = .failed(
                SearchViewModel.message(
                    for: error, generic: String(localized: "No se han podido cargar las salidas")))
        }
    }
}
