import SwiftUI

struct AirportRow: View {
    let airport: Airport
    @ScaledMetric private var codeWidth = 64.0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Text(airport.iataCode)
                .font(.title3.weight(.semibold).monospaced())
                .speechSpellsOutCharacters()
                .foregroundStyle(Color.accentColor)
                .frame(minWidth: codeWidth)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.12), in: .rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(airport.name).font(.headline)
                Text(airport.country).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(airport.name), \(spelledCode), \(airport.country)")
    }
    
    private var spelledCode: String {
        airport.iataCode.map(String.init).joined(separator: " ")
    }
}
