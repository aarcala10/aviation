import Testing

@testable import Aviation

@MainActor
struct SearchViewModelTests {
    private func makeVM(_ repo: MockAirportRepository) -> SearchViewModel {
        SearchViewModel(searchAirports: SearchAirportsUseCase(repository: repo))
    }
    
    @Test("search_success_showsAirports")
    func search_success_showsAirports() async {
        let vm = makeVM(MockAirportRepository { _ in [.madrid] })
        await vm.search("madrid")
        #expect(vm.state == .loaded([.madrid]))
    }
    
    @Test("search_noResults_showsEmptyState")
    func search_noResults_showsEmptyState() async {
        let vm = makeVM(MockAirportRepository { _ in [] })
        await vm.search(" zzzzz ")
        #expect(vm.state == .empty("zzzzz"))
    }
    
    @Test("search_failure_showsError")
    func search_failure_showsError() async {
        let vm = makeVM(MockAirportRepository { _ in throw APIError(code: "x", message: "boom") })
        await vm.search("madrid")
        guard case .failed = vm.state else {
            Issue.record("expected .failed, got \(vm.state)")
            return
        }
    }
    
    @Test("search_shortQuery_staysIdle")
    func search_shortQuery_staysIdle() async {
        let repo = MockAirportRepository { _ in [.madrid] }
        let vm = makeVM(repo)
        await vm.search("ma")
        #expect(vm.state == .idle)
        #expect(await repo.queries.isEmpty)
    }
    
    @Test("search_cancelledSearch_doesNotOverwriteNewerResults", .timeLimit(.minutes(1)))
    func search_cancelledSearch_doesNotOverwriteNewerResults() async {
        let gate = Gate()
        let repo = MockAirportRepository { query in
            if query == "madr" {
                await gate.wait()
                return [.barcelona]
            }
            return [.madrid]
        }
        let vm = makeVM(repo)
        let first = Task { await vm.search("madr") }
        // Bounded wait: the repository must receive the first call within 2 s.
        let deadline = ContinuousClock.now + .seconds(2)
        while await repo.queries.isEmpty, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
        guard await !repo.queries.isEmpty else {
            Issue.record("first search never reached the repository")
            first.cancel()
            await gate.open()
            await first.value
            return
        }
        first.cancel()
        await vm.search("madrid")
        await gate.open()
        await first.value
        #expect(vm.state == .loaded([.madrid]))
    }
}
