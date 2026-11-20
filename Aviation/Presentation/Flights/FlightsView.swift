import SwiftUI

struct FlightsView: View {
    @State var viewModel: FlightsViewModel
    @State private var attempt = 0
    @AccessibilityFocusState private var isFirstFlightFocused: Bool
    
    var body: some View {
        // The heading is the first element, so VoiceOver starts on it after a ScreenChanged post.
        VStack(alignment: .leading, spacing: 0) {
            Text("Salidas de \(viewModel.airport.iataCode)")
                .font(.title)
                .bold()
                .accessibilityLabel(Text("Salidas de \(viewModel.spokenCity)"))
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal)
            content
        }
        // The nav bar keeps its name (UI tests) but the heading above is the visible title.
        .navigationTitle(Text("Salidas de \(viewModel.airport.iataCode)"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .task(id: attempt) { await viewModel.load() }
        .onAppear(perform: announceScreen)
        .onChange(of: viewModel.state) { _, state in
            if case .loaded = state, attempt > 0 {
                // After a retry the new content starts at its first flight.
                isFirstFlightFocused = true
            } else {
                announceScreen()
            }
            if case .failed(let message) = state {
                // High priority so the screen change does not cut it off.
                var announcement = AttributedString(message)
                announcement.accessibilitySpeechAnnouncementPriority = .high
                AccessibilityNotification.Announcement(announcement).post()
            }
        }
    }
    
    private func announceScreen() {
        AccessibilityNotification.ScreenChanged().post()
    }
    
    @ViewBuilder private func row(_ flight: Flight, isFirst: Bool) -> some View {
        if isFirst {
            NavigationLink(value: flight) { FlightRow(flight: flight) }
                .accessibilityFocused($isFirstFlightFocused)
        } else {
            NavigationLink(value: flight) { FlightRow(flight: flight) }
        }
    }
    
    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Cargando salidas…")
        case .loaded:
            let sections = viewModel.sections
            let firstID = sections.first?.flights.first?.id
            List(sections) { section in
                Section {
                    ForEach(section.flights) { row($0, isFirst: $0.id == firstID) }
                } header: {
                    Text(FlightDate.title(section.date))
                }
            }
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
