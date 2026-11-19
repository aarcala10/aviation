import SwiftUI

@main
struct AviationApp: App {
    private let viewModel: SearchViewModel
    
    init() {
        let key =
            Bundle.main.object(forInfoDictionaryKey: "AviationstackAccessKey") as? String ?? ""
        let client = AviationstackClient(accessKey: key)
        viewModel = SearchViewModel(searchAirports: SearchAirportsUseCase(repository: client))
    }
    
    var body: some Scene {
        WindowGroup { SearchView(viewModel: viewModel) }
    }
}
