import XCTest

final class FlightsUITests: UIBase {
    @MainActor
    func testSearchAndOpenAirportShowsDepartures() {
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("madrid")
        
        let madrid = app.cells.containing(NSPredicate(format: "label CONTAINS 'Barajas'"))
            .firstMatch
        XCTAssertTrue(madrid.waitForExistence(timeout: 5))
        madrid.tap()
        
        XCTAssertTrue(app.navigationBars["Salidas de MAD"].waitForExistence(timeout: 5))
    }
}
