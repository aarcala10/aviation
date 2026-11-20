import SwiftUI

struct FlightDetailView: View {
    let viewModel: FlightDetailViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private enum Kind { case plain, spelled, time }
    
    var body: some View {
        List {
            Section { header }
            Section("Salida") {
                row("Terminal", viewModel.departureTerminal, .spelled)
                row("Puerta", viewModel.departureGate, .spelled)
                row("Programada", viewModel.departureScheduled, .time)
                row("Estimada", viewModel.departureEstimated, .time)
                row("Retraso", viewModel.departureDelay)
            }
            Section("Llegada") {
                row("Terminal", viewModel.arrivalTerminal, .spelled)
                row("Puerta", viewModel.arrivalGate, .spelled)
                row("Programada", viewModel.arrivalScheduled, .time)
                row("Estimada", viewModel.arrivalEstimated, .time)
                row("Retraso", viewModel.arrivalDelay)
            }
            Section("Vuelo") {
                row("Aerolínea", viewModel.airline)
                row("Número", viewModel.number, .spelled)
                row("Fecha", viewModel.date)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        // The nav bar keeps its name (UI tests) but the header is the visible title.
        .toolbar(removing: .title)
        // The header is the first element, so VoiceOver starts on it after a ScreenChanged post.
        .onAppear { AccessibilityNotification.ScreenChanged().post() }
    }
    
    private var header: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
        return VStack(alignment: .leading, spacing: 12) {
            layout {
                code(viewModel.originCode)
                Image(systemName: "airplane").font(.title2).foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                code(viewModel.destinationCode)
            }
            StatusBadge(status: viewModel.status, landedLate: viewModel.flight.landedLate)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.spokenHeader)
        .accessibilityAddTraits(.isHeader)
    }
    
    private func code(_ text: String) -> some View {
        Text(text).font(.largeTitle.weight(.bold).monospaced())
    }
    
    private func row(_ title: LocalizedStringKey, _ value: String, _ kind: Kind = .plain)
        -> some View
    {
        LabeledContent(title) {
            if value == FlightDetailViewModel.dash {
                // Otherwise VoiceOver says "em dash" (or spells it out).
                Text(value).accessibilityLabel("Sin dato")
            } else {
                valueText(value, kind)
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder private func valueText(_ value: String, _ kind: Kind) -> some View {
        switch kind {
        case .plain:
            Text(value)
        case .spelled:
            Text(value).speechSpellsOutCharacters()
        case .time:
            // Spoken without the leading zero ("5:55"), as in the row.
            Text(value).monospacedDigit()
                .accessibilityLabel(value.hasPrefix("0") ? String(value.dropFirst()) : value)
        }
    }
}
