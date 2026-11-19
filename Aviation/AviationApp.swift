import SwiftUI

@main
struct AviationApp: App {
    private let viewModel: SearchViewModel
    private let getDepartures: GetDeparturesUseCase
    
    init() {
        viewModel = SearchViewModel(
            searchAirports: SearchAirportsUseCase(repository: Self.loadRepository()))
        // Without a key the request fails with an API error and the flights screen shows it.
        let key = Bundle.main.object(forInfoDictionaryKey: "AviationstackAccessKey") as? String
        getDepartures = GetDeparturesUseCase(
            repository: AviationstackFlightRepository.live(accessKey: key ?? ""))
    }
    
    var body: some Scene {
        WindowGroup { SearchView(viewModel: viewModel, getDepartures: getDepartures) }
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
