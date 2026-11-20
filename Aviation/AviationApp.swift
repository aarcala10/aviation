import SwiftData
import SwiftUI

@main
struct AviationApp: App {
    private let viewModel: SearchViewModel
    private let getDepartures: GetDeparturesUseCase
    
    init() {
        let local = Self.loadLocalRepository()
        viewModel = SearchViewModel(
            searchAirports: SearchAirportsUseCase(
                repository: local.map { $0 as any AirportRepository }
                    ?? UnavailableAirportRepository()))
        // Without a key the request fails with an API error and the flights screen shows it.
        let key = Bundle.main.object(forInfoDictionaryKey: "AviationstackAccessKey") as? String
        let live = AviationstackFlightRepository.live(accessKey: key ?? "")
        // If the store cannot open, the app works without cache.
        let flights: any FlightRepository =
            (try? ModelContainer(for: CachedDepartures.self))
            .map { CachedFlightRepository(modelContainer: $0, wrapping: live) } ?? live
        getDepartures = GetDeparturesUseCase(repository: flights, cities: local)
    }
    
    var body: some Scene {
        WindowGroup { SearchView(viewModel: viewModel, getDepartures: getDepartures) }
    }
    
    /// If the bundled list cannot be read, searches fail and the view shows its error state.
    private static func loadLocalRepository() -> LocalAirportRepository? {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "json") else {
            return nil
        }
        return try? LocalAirportRepository(data: Data(contentsOf: url))
    }
}

private nonisolated struct UnavailableAirportRepository: AirportRepository {
    func airports(search: String) async throws -> [Airport] {
        throw CocoaError(.fileReadNoSuchFile)
    }
}
