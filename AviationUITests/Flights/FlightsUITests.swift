import XCTest

nonisolated final class FlightsUITests: UIBase {
    // Departures come from the fixture bundled in Debug, so these tests need no API key.
    @MainActor override var launchArguments: [String] { ["-uiTestFixtures"] }
    
    @MainActor
    private func openMadridDepartures() {
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
    
    @MainActor
    func testSearchAndOpenAirportShowsDepartures() {
        openMadridDepartures()
    }
    
    @MainActor
    func testOpenFlightShowsDetail() {
        openMadridDepartures()
        
        let flight = app.cells.containing(NSPredicate(format: "label CONTAINS 'AZ59'"))
            .firstMatch
        XCTAssertTrue(flight.waitForExistence(timeout: 5))
        flight.tap()
        
        XCTAssertTrue(app.navigationBars["AZ59"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Salida"].exists)
    }
}
