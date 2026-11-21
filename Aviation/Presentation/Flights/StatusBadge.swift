import SwiftUI

/// Clock-only pill that sits beside "En vuelo" when the flight left late.
struct DelayPill: View {
    var body: some View {
        Image(systemName: "clock")
            .foregroundStyle(Color("Accent/Highlight"))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("Accent/Highlight").opacity(0.15), in: .capsule)
            .accessibilityLabel("Retrasado")
    }
}

extension FlightStatus {
    var title: String {
        switch self {
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
    
    func spokenTitle(landedLate: Bool) -> String {
        landedLate ? String(localized: "Aterrizado con retraso") : title
    }
}

struct StatusBadge: View {
    let status: FlightStatus
    /// Landed with an arrival delay: still green, but with a clock instead of the arrival plane.
    var landedLate = false
    
    var body: some View {
        // Text in .primary: the status colours on their own 15 % tint fall below 4.5:1.
        // The colour stays on the symbol and the capsule; the text names the status.
        Label {
            Text(status.title)
        } icon: {
            Image(systemName: symbol).foregroundStyle(color)
        }
        // Icon beside the text even at accessibility sizes (the default stacks them), and the
        // natural width: a narrow parent would break "Programado" mid-word.
        .labelStyle(.titleAndIcon)
        .font(.caption.weight(.semibold))
        .fixedSize()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.spokenTitle(landedLate: landedLate))
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
