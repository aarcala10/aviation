import SwiftUI

struct FlightRow: View {
    let flight: Flight
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.number).font(.headline).speechSpellsOutCharacters()
                Text(flight.airline).font(.subheadline).foregroundStyle(.secondary)
                Text(
                    "\(Text(flight.destinationIATA).font(.subheadline.weight(.semibold).monospaced()).foregroundStyle(Color.accentColor)) \(flight.destinationName)"
                )
                .font(.subheadline)
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
            VStack(
                alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 8
            ) {
                Text(flight.scheduledTime).font(.body.monospacedDigit())
                StatusBadge(status: flight.status)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(
                "Vuelo \(Text(flight.number).speechSpellsOutCharacters()), \(flight.airline), a \(flight.destinationName) \(Text(flight.destinationIATA).speechSpellsOutCharacters()), \(flight.scheduledTime), \(StatusBadge(status: flight.status).title)"
            ))
    }
}
