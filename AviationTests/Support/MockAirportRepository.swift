@testable import Aviation

actor MockAirportRepository: AirportRepository {
    private(set) var queries: [String] = []
    private let handler: @Sendable (String) async throws -> [Airport]
    
    init(handler: @escaping @Sendable (String) async throws -> [Airport] = { _ in [] }) {
        self.handler = handler
    }
    
    func airports(search: String) async throws -> [Airport] {
        queries.append(search)
        return try await handler(search)
    }
}

/// One-shot gate: `wait()` suspends until `open()` (returns at once if already open).
actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }
    
    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }
}

extension Airport {
    static let madrid = Airport(
        name: "Adolfo Suarez Madrid-Barajas", iataCode: "MAD", country: "Spain")
    static let barcelona = Airport(name: "Barcelona El Prat", iataCode: "BCN", country: "Spain")
}
