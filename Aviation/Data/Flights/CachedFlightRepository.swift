import Foundation
import SwiftData

/// Disk cache (SwiftData) in front of another `FlightRepository`.
actor CachedFlightRepository: FlightRepository, ModelActor {
    nonisolated static let ttl: TimeInterval = 300
    
    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor
    private let wrapped: any FlightRepository
    private let now: @Sendable () -> Date
    
    init(
        modelContainer: ModelContainer, wrapping wrapped: any FlightRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.modelContainer = modelContainer
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
        self.wrapped = wrapped
        self.now = now
    }
    
    /// The cached repository, or `live` itself when the store cannot open (app works without cache).
    nonisolated static func wrapping(
        _ live: any FlightRepository, in makeContainer: () throws -> ModelContainer,
        now: @escaping @Sendable () -> Date = { Date() }
    ) -> any FlightRepository {
        guard let container = try? makeContainer() else { return live }
        return CachedFlightRepository(modelContainer: container, wrapping: live, now: now)
    }
    
    func departures(from iata: String, limit: Int, offset: Int) async throws -> [Flight] {
        let key = "\(iata)-\(limit)-\(offset)"
        let existing = try? modelContext.fetch(
            FetchDescriptor<CachedDepartures>(predicate: #Predicate { $0.key == key })
        ).first
        if let existing, now().timeIntervalSince(existing.fetchedAt) < Self.ttl,
            let flights = try? JSONDecoder().decode([Flight].self, from: existing.flights)
        {
            return flights
        }
        let flights = try await wrapped.departures(from: iata, limit: limit, offset: offset)
        // A failed save only loses the cache; the fresh flights are still returned.
        if let data = try? JSONEncoder().encode(flights) {
            if let existing {
                existing.fetchedAt = now()
                existing.flights = data
            } else {
                modelContext.insert(CachedDepartures(key: key, fetchedAt: now(), flights: data))
            }
            try? modelContext.save()
        }
        return flights
    }
}
