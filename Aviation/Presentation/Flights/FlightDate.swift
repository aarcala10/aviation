import Foundation

enum FlightDate {
    /// "2026-11-20" -> «viernes, 20 de noviembre». Parsed and formatted in UTC so the day never
    /// moves with the device time zone (the times are shown as received for the same reason).
    static func title(_ date: String) -> String {
        guard let day = try? Date(date, strategy: .iso8601.year().month().day()) else {
            return String(localized: "Sin fecha")
        }
        var style = Date.FormatStyle(timeZone: .gmt).weekday(.wide).day().month(.wide)
        style.calendar = Calendar(identifier: .gregorian)
        // The app is only localized in Spanish; follow its language, not the device region.
        style.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "es")
        return day.formatted(style)
    }
}
