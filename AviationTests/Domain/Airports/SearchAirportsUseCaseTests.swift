import Testing

@testable import Aviation

struct SearchAirportsUseCaseTests {
    @Test("search_trimsQueryBeforeCallingRepository")
    func search_trimsQueryBeforeCallingRepository() async throws {
        let repo = MockAirportRepository { _ in [.madrid] }
        let result = try await SearchAirportsUseCase(repository: repo)("  madrid \n")
        #expect(await repo.queries == ["madrid"])
        #expect(result == [.madrid])
    }
    
    @Test("search_withLessThanThreeCharacters_returnsEmptyWithoutCallingRepository")
    func search_withLessThanThreeCharacters_returnsEmptyWithoutCallingRepository() async throws {
        let repo = MockAirportRepository { _ in [.madrid] }
        let result = try await SearchAirportsUseCase(repository: repo)(" ma ")
        #expect(result.isEmpty)
        #expect(await repo.queries.isEmpty)
    }
    
    @Test("search_propagatesRepositoryError")
    func search_propagatesRepositoryError() async {
        let repo = MockAirportRepository { _ in throw ServiceError.unknown }
        await #expect(throws: ServiceError.unknown) {
            try await SearchAirportsUseCase(repository: repo)("madrid")
        }
    }
}
