import Foundation
import Testing

@testable import Aviation

struct FlightsViewModelTests {
    private func makeVM(_ repo: MockFlightRepository) -> FlightsViewModel {
        FlightsViewModel(airport: .madrid, getDepartures: GetDeparturesUseCase(repository: repo))
    }
    
    @Test("load_success_showsFlights")
    func load_success_showsFlights() async {
        let flight = Flight.sample()
        let vm = makeVM(MockFlightRepository { _ in [flight] })
        await vm.load()
        #expect(vm.state == .loaded([flight]))
    }
    
    @Test("load_noFlights_showsEmptyState")
    func load_noFlights_showsEmptyState() async {
        let vm = makeVM(MockFlightRepository { _ in [] })
        await vm.load()
        #expect(vm.state == .empty)
    }
    
    @Test("load_failure_showsError")
    func load_failure_showsError() async {
        let vm = makeVM(MockFlightRepository { _ in throw URLError(.notConnectedToInternet) })
        await vm.load()
        #expect(vm.state == .failed("Comprueba tu conexión"))
    }
    
    @Test("load_cancelled_neverLeavesLoadingNorOverwritesNewerResult", .timeLimit(.minutes(1)))
    func load_cancelled_neverLeavesLoadingNorOverwritesNewerResult() async {
        let old = Flight.sample(number: "OLD")
        let new = Flight.sample(number: "NEW")
        let gate = Gate()
        let attempts = Counter()
        let repo = MockFlightRepository { _ in
            if await attempts.next() == 1 {
                await gate.wait()
                return [old]
            }
            return [new]
        }
        let vm = makeVM(repo)
        
        // A cancelled load that nothing replaces must not stay in .loading.
        let alone = Task { await vm.load() }
        await waitForCalls(1, on: repo)
        alone.cancel()
        await gate.open()
        await alone.value
        #expect(vm.state != .loading)
        
        // A cancelled load resuming after a newer one finished must not overwrite it.
        let gate2 = Gate()
        let attempts2 = Counter()
        let repo2 = MockFlightRepository { _ in
            if await attempts2.next() == 1 {
                await gate2.wait()
                return [old]
            }
            return [new]
        }
        let vm2 = makeVM(repo2)
        let first = Task { await vm2.load() }
        await waitForCalls(1, on: repo2)
        first.cancel()
        await vm2.load()
        await gate2.open()
        await first.value
        #expect(vm2.state == .loaded([new]))
    }
    
    private func waitForCalls(_ count: Int, on repo: MockFlightRepository) async {
        let deadline = ContinuousClock.now + .seconds(2)
        while await repo.calls.count < count, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
    
    @Test("retry_afterFailure_loadsAgain")
    func retry_afterFailure_loadsAgain() async {
        let flight = Flight.sample()
        let attempts = Counter()
        let repo = MockFlightRepository { _ in
            if await attempts.next() == 1 {
                throw URLError(.notConnectedToInternet)
            }
            return [flight]
        }
        let vm = makeVM(repo)
        await vm.load()
        guard case .failed = vm.state else {
            Issue.record("expected .failed, got \(vm.state)")
            return
        }
        await vm.load()
        #expect(vm.state == .loaded([flight]))
        #expect(await repo.calls.count == 2)
    }
}

private actor Counter {
    private var value = 0
    func next() -> Int {
        value += 1
        return value
    }
}
