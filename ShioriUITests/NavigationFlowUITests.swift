import XCTest

final class NavigationFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        app.launch()
        return app
    }

    @MainActor
    func test起動したら旅行一覧が表示されること() throws {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["旅行一覧"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["東京観光"].waitForExistence(timeout: 5))
    }

    @MainActor
    func test旅行一覧の東京観光から旅程明細に遷移すること() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["東京観光"].waitForExistence(timeout: 5))
        app.staticTexts["東京観光"].tap()

        XCTAssertTrue(app.navigationBars["東京観光"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["旅程を編集"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["旅程を見る"].waitForExistence(timeout: 5))
    }

    @MainActor
    func test旅程閲覧には旅程全体が表示されること() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["東京観光"].waitForExistence(timeout: 5))
        app.staticTexts["東京観光"].tap()
        XCTAssertTrue(app.staticTexts["旅程を見る"].waitForExistence(timeout: 5))
        app.staticTexts["旅程を見る"].tap()

        XCTAssertTrue(app.navigationBars["旅程を見る"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["旅程全体"].waitForExistence(timeout: 5))
    }

    @MainActor
    func test旅程閲覧には予定時間の警告メッセージが表示されること() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["東京観光"].waitForExistence(timeout: 5))
        app.staticTexts["東京観光"].tap()
        XCTAssertTrue(app.staticTexts["旅程を見る"].waitForExistence(timeout: 5))
        app.staticTexts["旅程を見る"].tap()

        XCTAssertTrue(app.staticTexts["予定時間が重なっている行き先があります"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["並び順と到着時刻が一致していない行き先があります"].waitForExistence(timeout: 5))
    }

    @MainActor
    func test旅程編集画面で候補を追加したら候補一覧に追加表示されること() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["東京観光"].waitForExistence(timeout: 5))
        app.staticTexts["東京観光"].tap()
        XCTAssertTrue(app.staticTexts["旅程を編集"].waitForExistence(timeout: 5))
        app.staticTexts["旅程を編集"].tap()

        XCTAssertTrue(app.navigationBars["旅程作成"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["行き先候補"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["東京タワー"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["新宿御苑"].exists)

        let titleField = app.textFields["候補名を入力"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("新宿御苑")

        app.buttons["候補に追加"].tap()

        XCTAssertTrue(app.staticTexts["新宿御苑"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["東京タワー"].exists)
    }
}
