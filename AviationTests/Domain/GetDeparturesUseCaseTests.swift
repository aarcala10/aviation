import Testing

@testable import Aviation

struct GetDeparturesUseCaseTests {
    @Test("departures_requestsFirstPageOfHundred")
    func departures_requestsFirstPageOfHundred() async throws {
        let repo = MockFlightRepository()
        _ = try await GetDeparturesUseCase(repository: repo)(from: "MAD")
        #expect(await repo.calls == [.init(iata: "MAD", limit: 100, offset: 0)])
    }
    
    @Test("departures_skipsCodeshares")
    func departures_skipsCodeshares() async throws {
        let operated = Flight.sample(number: "AZ59")
        let repo = MockFlightRepository { _ in
            [.sample(number: "V76135", isCodeshare: true), operated]
        }
        let flights = try await GetDeparturesUseCase(repository: repo)(from: "MAD")
        #expect(flights == [operated])
    }
    
    @Test("departures_propagatesRepositoryError")
    func departures_propagatesRepositoryError() async {
        let repo = MockFlightRepository { _ in throw APIError(code: "x", message: "boom") }
        await #expect(throws: APIError(code: "x", message: "boom")) {
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
