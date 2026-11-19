import SwiftUI

@main
struct AviationApp: App {
    private let viewModel: SearchViewModel
    
    init() {
        viewModel = SearchViewModel(
            searchAirports: SearchAirportsUseCase(repository: Self.loadRepository()))
    }
    
    var body: some Scene {
        WindowGroup { SearchView(viewModel: viewModel) }
    }
    
    /// If the bundled list cannot be read, searches fail and the view shows its error state.
    private static func loadRepository() -> any AirportRepository {
        do {
            guard let url = Bundle.main.url(forResource: "airports", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            return try LocalAirportRepository(data: Data(contentsOf: url))
        } catch {
            return UnavailableAirportRepository()
        }
    }
}

private struct UnavailableAirportRepository: AirportRepository {
    func airports(search: String) async throws -> [Airport] {
        throw CocoaError(.fileReadNoSuchFile)
    }
}
