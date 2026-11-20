import SwiftUI

struct SearchView: View {
    @State var viewModel: SearchViewModel
    let getDepartures: GetDeparturesUseCase
    @State private var query = ""
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Aeropuertos")
                .navigationDestination(for: Airport.self) {
                    FlightsView(
                        viewModel: FlightsViewModel(airport: $0, getDepartures: getDepartures))
                }
                .navigationDestination(for: Flight.self) {
                    FlightDetailView(viewModel: FlightDetailViewModel(flight: $0))
                }
                .searchable(text: $query, prompt: "Buscar aeropuerto")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .task(id: query) {
            if !query.isEmpty {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
            }
            await viewModel.search(query)
        }
        .onChange(of: viewModel.state) { _, state in
            switch state {
            case .loaded(let airports):
                AccessibilityNotification.Announcement(
                    String(localized: "\(airports.count) aeropuertos encontrados")
                ).post()
            case .failed(let message):
                AccessibilityNotification.Announcement(message).post()
            default:
                break
            }
        }
    }
    
    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                "Busca un aeropuerto",
                systemImage: "airplane.departure",
                description: Text("Escribe un nombre, una ciudad o un código IATA"))
        case .loading:
            ProgressView("Buscando…")
        case .loaded(let airports):
            List(airports) { airport in
                NavigationLink(value: airport) { AirportRow(airport: airport) }
            }
        case .empty(let text):
            ContentUnavailableView.search(text: text)
        case .failed(let message):
            ContentUnavailableView(
                "Error en la búsqueda",
                systemImage: "exclamationmark.triangle",
                description: Text(message))
        }
    }
}
