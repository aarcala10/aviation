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
    
    // RED stub: forwards without caching.
    func departures(from iata: String, limit: Int, offset: Int) async throws -> [Flight] {
        try await wrapped.departures(from: iata, limit: limit, offset: offset)
    }
}
