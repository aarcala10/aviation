import XCTest

final class SearchAirportsUITests: UIBase {
    @MainActor
    func testSearchingMadShowsMadridBarajas() {
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("mad")
        
        let result = app.cells.containing(NSPredicate(format: "label CONTAINS 'Barajas'"))
            .firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
    }
}
