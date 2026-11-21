import XCTest

nonisolated final class FlightsPaginationUITests: UIBase {
    @MainActor override var launchArguments: [String] {
        ["-uiTestFixtures", "-uiTestPagedFixtures"]
    }
    
    @MainActor
    func testLoadMoreButtonLoadsNextPageAndKeepsItAfterDetail() {
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("madrid")
        let madrid = app.cells.containing(NSPredicate(format: "label CONTAINS 'Barajas'"))
            .firstMatch
        XCTAssertTrue(madrid.waitForExistence(timeout: 5))
        madrid.tap()
        XCTAssertTrue(app.navigationBars["Salidas de MAD"].waitForExistence(timeout: 5))
        
        let loadMore = app.buttons["Cargar más salidas"]
        for _ in 0..<40 where !loadMore.exists { app.swipeUp() }
        XCTAssertTrue(loadMore.waitForExistence(timeout: 5))
        loadMore.tap()
        
        let last = app.cells.containing(NSPredicate(format: "label CONTAINS 'XX2004'")).firstMatch
        for _ in 0..<40 where !last.exists { app.swipeUp() }
        XCTAssertTrue(last.waitForExistence(timeout: 5))
        XCTAssertFalse(loadMore.exists)
        screenshot("departures-end-of-list")
        
        last.tap()
        XCTAssertTrue(app.navigationBars["XX2004"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(last.waitForExistence(timeout: 5))
    }
}
