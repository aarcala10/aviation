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
    
    @Test("airports_bundledData_citiesInSpanish")
    func airports_bundledData_citiesInSpanish() async throws {
        let repo = try LocalAirportRepository(data: Fixture.bundledAirports())
        #expect(try await repo.airports(search: "lisboa").map(\.iataCode).contains("LIS"))
        #expect(repo.city(forIATA: "FCO") == "Roma")
    }
    
    @Test(
        "airports_bundledData_localNamesAreTranslatedByCode",
        arguments: [("CDG", "París"), ("NAP", "Nápoles"), ("VCE", "Venecia"), ("MXP", "Milán")])
    func airports_bundledData_localNamesAreTranslatedByCode(iata: String, city: String)
        async throws
    {
        let repo = try LocalAirportRepository(data: Fixture.bundledAirports())
        #expect(repo.city(forIATA: iata) == city)
        #expect(try await repo.airports(search: city).map(\.iataCode).contains(iata))
    }
    
    @Test("airports_exactCityMatch_comesBeforeNameMatches")
    func airports_exactCityMatch_comesBeforeNameMatches() async throws {
        let repo = try LocalAirportRepository(data: Fixture.bundledAirports())
        let codes = try await repo.airports(search: "madrid").map(\.iataCode)
        let mad = try #require(codes.firstIndex(of: "MAD"))
        let clq = try #require(codes.firstIndex(of: "CLQ"))
        #expect(mad < clq)
    }
    
    @Test("airports_invalidData_throws")
    func airports_invalidData_throws() {
        #expect(throws: (any Error).self) {
            try LocalAirportRepository(data: Data("not json".utf8))
        }
    }
}
