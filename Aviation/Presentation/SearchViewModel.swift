import Observation

@MainActor @Observable
final class SearchViewModel {
    enum State: Equatable {
        case idle, loading
        case loaded([Airport])
        case empty(String)
        case failed(String)
    }
    
    private(set) var state: State = .idle
    private let searchAirports: SearchAirportsUseCase
    
    init(searchAirports: SearchAirportsUseCase) {
        self.searchAirports = searchAirports
    }
    
    // RED stub.
    func search(_ query: String) async {
        state = .loading
    }
}
