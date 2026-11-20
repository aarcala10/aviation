import Foundation
import Testing

@testable import Aviation

struct LocalAirportRepositoryTests {
    private func repository() throws -> LocalAirportRepository {
        try LocalAirportRepository(data: Fixture.data("airports"))
    }
    
    @Test("airports_matchesByIataCode")
    func airports_matchesByIataCode() async throws {
        let result = try await repository().airports(search: "mad")
        #expect(
            result == [
                Airport(name: "Adolfo Suárez Madrid-Barajas", iataCode: "MAD", country: "España")
            ])
    }
    
    @Test("airports_matchesByNameOrCityIgnoringCaseAndDiacritics")
    func airports_matchesByNameOrCityIgnoringCaseAndDiacritics() async throws {
        let repo = try repository()
        #expect(try await repo.airports(search: "SUAREZ").map(\.iataCode) == ["MAD"])
        #expect(try await repo.airports(search: "malaga").map(\.iataCode) == ["AGP"])
    }
    
    @Test("airports_invalidData_throws")
    func airports_invalidData_throws() {
        #expect(throws: (any Error).self) {
            try LocalAirportRepository(data: Data("not json".utf8))
        }
    }
}
