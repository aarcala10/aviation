import XCTest

class UIBase: XCTestCase {
    @MainActor var app: XCUIApplication!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
}
