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
    
    /// UI tests: bundled JSON (Debug builds only) instead of the network, no cache. `-uiTestPagedFixtures`
    /// serves 100 flights at offset 0 and 5 at offset 100.
    private static func fixtureRepository() -> AviationstackFlightRepository {
        func fixture(_ name: String) -> Data {
            Bundle.main.url(forResource: name, withExtension: "json")
                .flatMap { try? Data(contentsOf: $0) } ?? Data()
        }
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-uiTestPagedFixtures") else {
            let data = fixture("flights")
            return AviationstackFlightRepository(accessKey: "") { _ in data }
        }
        let first = fixture("flights_page1")
        let second = fixture("flights_page2")
        return AviationstackFlightRepository(accessKey: "") { request in
            let offset = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "offset" }?.value
            return offset == "100" ? second : first
        }
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
