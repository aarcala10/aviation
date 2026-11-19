import SwiftUI

@main
struct AviationApp: App {
    private let viewModel: SearchViewModel
    
    init() {
        // RED placeholder: green loads the bundled airport list.
        let repository = try! LocalAirportRepository(data: Data())
        viewModel = SearchViewModel(searchAirports: SearchAirportsUseCase(repository: repository))
    }
    
    var body: some Scene {
        WindowGroup { SearchView(viewModel: viewModel) }
    }
}
