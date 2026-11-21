import Testing

@testable import Aviation

struct GetDeparturesUseCaseTests {
    private func page(_ count: Int, prefix: String = "F", isCodeshare: Bool = false) -> [Flight] {
        (0..<count).map { .sample(number: "\(prefix)\($0)", isCodeshare: isCodeshare) }
    }
    
    @Test("departures_requestsPageAtOffset")
    func departures_requestsPageAtOffset() async throws {
        let repo = MockFlightRepository()
        _ = try await GetDeparturesUseCase(repository: repo)(from: "MAD", offset: 200)
        #expect(await repo.calls == [.init(iata: "MAD", limit: 100, offset: 200)])
    }
    
    @Test("departures_fullPage_hasNextOffset")
    func departures_fullPage_hasNextOffset() async throws {
        let raw = page(100)
        let repo = MockFlightRepository { _ in raw }
        let result = try await GetDeparturesUseCase(repository: repo)(from: "MAD", offset: 100)
        #expect(result.nextOffset == 200)
    }
    
    @Test("departures_shortPage_hasNoNextOffset")
    func departures_shortPage_hasNoNextOffset() async throws {
        let raw = page(99)
        let repo = MockFlightRepository { _ in raw }
        let result = try await GetDeparturesUseCase(repository: repo)(from: "MAD", offset: 100)
        #expect(result.nextOffset == nil)
    }
    
    @Test("departures_fullPageOfCodeshares_stillHasNextOffset")
    func departures_fullPageOfCodeshares_stillHasNextOffset() async throws {
        let raw = page(100, isCodeshare: true)
        let repo = MockFlightRepository { _ in raw }
        let result = try await GetDeparturesUseCase(repository: repo)(from: "MAD", offset: 100)
        #expect(result.flights.isEmpty)
        #expect(result.nextOffset == 200)
    }
    
    @Test("departures_skipsCodeshares")
    func departures_skipsCodeshares() async throws {
        let operated = Flight.sample(number: "AZ59")
        let repo = MockFlightRepository { _ in
            [.sample(number: "V76135", isCodeshare: true), operated]
        }
        let flights = try await GetDeparturesUseCase(repository: repo)(from: "MAD").flights
        #expect(flights == [operated])
    }
    
    @Test("departures_propagatesRepositoryError")
    func departures_propagatesRepositoryError() async {
        let repo = MockFlightRepository { _ in throw ServiceError.unknown }
        await #expect(throws: ServiceError.unknown) {
            try await GetDeparturesUseCase(repository: repo)(from: "MAD")
        }
    }
}

struct FlightStatusTests {
    @Test("status_withDepartureDelay_isDelayed")
    func status_withDepartureDelay_isDelayed() {
        #expect(Flight.sample(status: .scheduled, delay: 25).status == .delayed)
        #expect(Flight.sample(status: .active, delay: 25).status == .delayed)
    }
    
    @Test("status_cancelledWithDelay_staysCancelled")
    func status_cancelledWithDelay_staysCancelled() {
        #expect(Flight.sample(status: .cancelled, delay: 25).status == .cancelled)
    }
}
