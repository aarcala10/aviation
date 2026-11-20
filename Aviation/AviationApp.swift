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
        let flights: any FlightRepository
        if ProcessInfo.processInfo.arguments.contains("-uiTestFixtures") {
            flights = Self.fixtureRepository()
        } else {
            let key = Bundle.main.object(forInfoDictionaryKey: "AviationstackAccessKey") as? String
            let live = AviationstackFlightRepository.live(accessKey: key ?? "")
            flights = CachedFlightRepository.wrapping(live) {
                try ModelContainer(for: CachedDepartures.self)
            }
        }
        getDepartures = GetDeparturesUseCase(repository: flights, cities: local)
    }
    
    /// UI tests: the bundled `flights.json` (Debug builds only) instead of the network, no cache.
    private static func fixtureRepository() -> AviationstackFlightRepository {
        let data =
            Bundle.main.url(forResource: "flights", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) } ?? Data()
        return AviationstackFlightRepository(accessKey: "") { _ in data }
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
