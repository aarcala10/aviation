import SwiftUI

struct FlightsView: View {
    @State var viewModel: FlightsViewModel
    @State private var attempt = 0
    
    var body: some View {
        content
            .navigationTitle(Text("Salidas de \(viewModel.airport.iataCode)"))
            .navigationBarTitleDisplayMode(.inline)
            .task(id: attempt) { await viewModel.load() }
            .onChange(of: viewModel.state) { _, state in
                if case .failed(let message) = state {
                    AccessibilityNotification.Announcement(message).post()
                }
            }
    }
    
    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Cargando salidas…")
        case .loaded(let flights):
            List(flights) { FlightRow(flight: $0) }
        case .empty:
            ContentUnavailableView(
                "No hay salidas",
                systemImage: "airplane.departure")
        case .failed(let message):
            ContentUnavailableView {
                Label("Error al cargar las salidas", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Reintentar") { attempt += 1 }
            }
        }
    }
}
