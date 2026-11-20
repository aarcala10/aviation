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
    
    private func page(_ count: Int, prefix: String, isCodeshare: Bool = false) -> [Flight] {
        (0..<count).map { .sample(number: "\(prefix)\($0)", isCodeshare: isCodeshare) }
    }
    
    private func offsets(_ repo: MockFlightRepository) async -> [Int] {
        await repo.calls.map(\.offset)
    }
    
    @Test("loadMore_appendsNextPage")
    func loadMore_appendsNextPage() async {
        let page1 = page(100, prefix: "A")
        let page2 = page(10, prefix: "B")
        let repo = MockFlightRepository { $0.offset == 0 ? page1 : page2 }
        let vm = makeVM(repo)
        await vm.load()
        #expect(vm.more == .available)
        await vm.loadMore()
        #expect(await offsets(repo) == [0, 100])
        #expect(vm.state == .loaded(page1 + page2))
    }
    
    @Test("loadMore_whileLoading_requestsOnce", .timeLimit(.minutes(1)))
    func loadMore_whileLoading_requestsOnce() async {
        let page1 = page(100, prefix: "A")
        let gate = Gate()
        let repo = MockFlightRepository { call in
            if call.offset == 0 { return page1 }
            await gate.wait()
            return []
        }
        let vm = makeVM(repo)
        await vm.load()
        let first = Task { await vm.loadMore() }
        await waitForCalls(2, on: repo)
        let second = Task { await vm.loadMore() }
        try? await Task.sleep(for: .milliseconds(50))
        await gate.open()
        await first.value
        await second.value
        #expect(await offsets(repo) == [0, 100])
    }
    
    @Test("loadMore_lastPage_stopsRequesting")
    func loadMore_lastPage_stopsRequesting() async {
        let short = page(5, prefix: "A")
        let repo = MockFlightRepository { _ in short }
        let vm = makeVM(repo)
        await vm.load()
        #expect(vm.more == .complete)
        await vm.loadMore()
        #expect(await offsets(repo) == [0])
    }
    
    @Test("loadMore_pageWithoutNewFlights_loadsTheNextOne")
    func loadMore_pageWithoutNewFlights_loadsTheNextOne() async {
        let page1 = page(100, prefix: "A")
        let shares = page(100, prefix: "S", isCodeshare: true)
        let page3 = page(20, prefix: "C")
        let repo = MockFlightRepository { call in
            switch call.offset {
            case 0: return page1
            case 100: return shares
            default: return page3
            }
        }
        let vm = makeVM(repo)
        await vm.load()
        await vm.loadMore()
        #expect(await offsets(repo) == [0, 100, 200])
        #expect(vm.state == .loaded(page1 + page3))
    }
    
    @Test("loadMore_dropsFlightsAlreadyShown")
    func loadMore_dropsFlightsAlreadyShown() async {
        let page1 = page(100, prefix: "A")
        let fresh = Flight.sample(number: "NEW")
        let repo = MockFlightRepository { $0.offset == 0 ? page1 : [page1[0], fresh] }
        let vm = makeVM(repo)
        await vm.load()
        await vm.loadMore()
        #expect(vm.state == .loaded(page1 + [fresh]))
    }
    
    @Test("loadMore_failure_keepsFlightsAndShowsError")
    func loadMore_failure_keepsFlightsAndShowsError() async {
        let page1 = page(100, prefix: "A")
        let repo = MockFlightRepository { call in
            if call.offset == 0 { return page1 }
            throw URLError(.notConnectedToInternet)
        }
        let vm = makeVM(repo)
        await vm.load()
        await vm.loadMore()
        #expect(vm.state == .loaded(page1))
        #expect(vm.more == .failed("Comprueba tu conexión"))
    }
    
    @Test("loadMore_retryAfterFailure_requestsSamePage")
    func loadMore_retryAfterFailure_requestsSamePage() async {
        let page1 = page(100, prefix: "A")
        let page2 = page(10, prefix: "B")
        let attempts = Counter()
        let repo = MockFlightRepository { call in
            if call.offset == 0 { return page1 }
            if await attempts.next() == 1 { throw URLError(.notConnectedToInternet) }
            return page2
        }
        let vm = makeVM(repo)
        await vm.load()
        await vm.loadMore()
        await vm.loadMore()
        #expect(await offsets(repo) == [0, 100, 100])
        #expect(vm.state == .loaded(page1 + page2))
    }
    
    @Test(
        "load_afterLoadMore_startsAgainFromFirstPage_andIgnoresLatePage", .timeLimit(.minutes(1)))
    func load_afterLoadMore_startsAgainFromFirstPage_andIgnoresLatePage() async {
        let old = page(100, prefix: "A")
        let fresh = page(100, prefix: "N")
        let late = page(10, prefix: "L")
        let gate = Gate()
        let firstPages = Counter()
        let repo = MockFlightRepository { call in
            if call.offset == 0 { return await firstPages.next() == 1 ? old : fresh }
            await gate.wait()
            return late
        }
        let vm = makeVM(repo)
        await vm.load()
        let held = Task { await vm.loadMore() }
        await waitForCalls(2, on: repo)
        await vm.load()
        #expect(await offsets(repo) == [0, 100, 0])
        #expect(vm.state == .loaded(fresh))
        await gate.open()
        await held.value
        #expect(vm.state == .loaded(fresh))
        await vm.loadMore()
        #expect(await offsets(repo) == [0, 100, 0, 100])
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
