import SwiftUI

struct FlightRow: View {
    let flight: Flight
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    /// Spoken form only ("5:55", not "05:55", so a leading zero is not read out).
    private var departure: String {
        let time =
            flight.scheduledTime.hasPrefix("0")
            ? String(flight.scheduledTime.dropFirst()) : flight.scheduledTime
        return time.hasPrefix("1:")
            ? String(localized: "Sale a la \(time)") : String(localized: "Sale a las \(time)")
    }
    
    /// In the air after leaving late: "En vuelo" plus a clock pill, not "Retrasado".
    private var departedLate: Bool { flight.reportedStatus == .active && flight.delayMinutes > 0 }
    private var badgeStatus: FlightStatus { departedLate ? .active : flight.status }
    
    private var spokenNumber: Text {
        flight.number.isEmpty ? Text("sin número") : Text(flight.number).speechSpellsOutCharacters()
    }
    
    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 4) {
                if flight.number.isEmpty {
                    Text("Sin número").font(.headline).foregroundStyle(.secondary)
                } else {
                    Text(flight.number).font(.headline).speechSpellsOutCharacters()
                }
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
                HStack(spacing: 6) {
                    if departedLate { DelayPill() }
                    StatusBadge(status: badgeStatus, landedLate: flight.landedLate)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(
                "Vuelo \(spokenNumber), \(flight.airline). A \(flight.spokenDestination). \(departure). \(badgeStatus.spokenTitle(landedLate: flight.landedLate))\(departedLate ? String(localized: ", retrasado") : "")."
            ))
    }
}
