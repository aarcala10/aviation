import XCTest

nonisolated class UIBase: XCTestCase {
    @MainActor var app: XCUIApplication!
    
    /// Launch arguments of the app; override to add some (e.g. `-uiTestFixtures`).
    @MainActor var launchArguments: [String] { [] }
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = launchArguments
        app.launch()
    }
}
