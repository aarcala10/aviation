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
