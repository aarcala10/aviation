import SwiftUI

struct StatusBadge: View {
    let status: FlightStatus
    /// Landed with an arrival delay: still green, but with a clock instead of the arrival plane.
    var landedLate = false
    
    var body: some View {
        // Text in .primary: the status colours on their own 15 % tint fall below 4.5:1.
        // The colour stays on the symbol and the capsule; the text names the status.
        Label {
            Text(title)
        } icon: {
            Image(systemName: symbol).foregroundStyle(color)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenTitle)
    }
    
    var spokenTitle: String {
        landedLate ? String(localized: "Aterrizado con retraso") : title
    }
    
    var title: String {
        switch status {
        case .scheduled: String(localized: "Programado")
        case .active: String(localized: "En vuelo")
        case .landed: String(localized: "Aterrizado")
        case .delayed: String(localized: "Retrasado")
        case .cancelled: String(localized: "Cancelado")
        case .diverted: String(localized: "Desviado")
        case .incident: String(localized: "Incidente")
        case .unknown: String(localized: "Desconocido")
        }
    }
    
    private var symbol: String {
        switch status {
        case .scheduled, .unknown: "clock"
        case .active: "airplane"
        case .landed: landedLate ? "clock" : "airplane.arrival"
        case .delayed: "exclamationmark.circle"
        case .cancelled: "xmark.circle"
        case .diverted, .incident: "exclamationmark.triangle"
        }
    }
    
    private var color: Color {
        switch status {
        case .scheduled, .unknown: .secondary
        case .active: .accentColor
        case .landed: .green
        case .delayed: Color("Accent/Highlight")
        case .cancelled, .diverted, .incident: .red
        }
    }
}
