import Foundation
import SwiftData

@Model
final class CachedDepartures {
    /// IATA + limit + offset.
    @Attribute(.unique) var key: String
    var fetchedAt: Date
    /// JSON-encoded `[Flight]` page, as the repository returned it.
    var flights: Data
    
    init(key: String, fetchedAt: Date, flights: Data) {
        self.key = key
        self.fetchedAt = fetchedAt
        self.flights = flights
    }
}
