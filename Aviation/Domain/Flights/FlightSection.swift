/// Flights of one calendar day ("yyyy-MM-dd", as received; empty when the API gave none).
nonisolated struct FlightSection: Equatable, Sendable, Identifiable {
    let date: String
    let flights: [Flight]
    var id: String { date }
}

nonisolated extension Array where Element == Flight {
    /// Newest date first (flights without a date last); inside a day, earliest time first,
    /// keeping the API order for equal times.
    func groupedByDate() -> [FlightSection] {
        let groups = Dictionary(grouping: enumerated(), by: { $0.element.date })
        let dates = groups.keys.sorted { a, b in
            a.isEmpty != b.isEmpty ? b.isEmpty : a > b
        }
        return dates.map { date in
            let ordered = groups[date, default: []].sorted {
                ($0.element.scheduledTime, $0.offset) < ($1.element.scheduledTime, $1.offset)
            }
            return FlightSection(date: date, flights: ordered.map(\.element))
        }
    }
}
