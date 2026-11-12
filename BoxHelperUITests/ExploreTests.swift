import XCTest

/// Exploration pass: launch the real app, then record the screen and the
/// accessibility tree of each tab so the capture flow can be written against it.
final class ExploreTests: XCTestCase {
    func testExplore() throws {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        sleep(6)
        Capture.both("00-launch", app: app, in: self)

        for label in ["Continue", "Weiter", "Get Started", "Close", "OK"] {
            let button = app.buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                sleep(2)
                Capture.both("01-after-\(label)", app: app, in: self)
            }
        }

        let tabs = app.tabBars.buttons
        for index in 0..<tabs.count {
            let tab = tabs.element(boundBy: index)
            let name = tab.label.replacingOccurrences(of: " ", with: "_")
            tab.tap()
            sleep(2)
            Capture.both(String(format: "10-tab-%02d-%@", index, name), app: app, in: self)
        }
    }
}
