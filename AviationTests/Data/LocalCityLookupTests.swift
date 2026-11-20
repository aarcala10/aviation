import Foundation
import Testing

@testable import Aviation

struct LocalCityLookupTests {
    @Test("city_knownCode_returnsCityIgnoringCase")
    func city_knownCode_returnsCityIgnoringCase() throws {
        let repo = try LocalAirportRepository(data: Fixture.data("airports"))
        #expect(repo.city(forIATA: "MAD") == "Madrid")
        #expect(repo.city(forIATA: "bcn") == "Barcelona")
    }
    
    @Test("city_unknownCodeOrEmptyCity_returnsNil")
    func city_unknownCodeOrEmptyCity_returnsNil() throws {
        let json = #"[{"n":"No City Field","c":"","i":"ZZZ","k":"ES"}]"#
        let repo = try LocalAirportRepository(data: Data(json.utf8))
        #expect(repo.city(forIATA: "ZZZ") == nil)
        #expect(repo.city(forIATA: "QQQ") == nil)
    }
}
