import XCTest

/// Enters generic sample boxes through BoxHelper's own Create tab, then
/// captures the real screens that show them. Nothing in the app is stubbed.
final class CaptureTests: XCTestCase {
    private struct SampleBox {
        let name: String
        let location: String
        let items: [String]
    }

    private let samples = [
        SampleBox(name: "Kitchen essentials", location: "Kitchen",
                  items: ["Coffee mugs", "Cast-iron pan", "Measuring cups", "Tea towels"]),
        SampleBox(name: "Winter clothes", location: "Attic",
                  items: ["Wool scarves", "Ski gloves", "Down jacket"]),
        SampleBox(name: "Camping gear", location: "Garage",
                  items: ["Tent", "Sleeping bag", "Headlamp", "Camp stove"]),
        SampleBox(name: "Holiday decorations", location: "Garage",
                  items: ["String lights", "Ornaments", "Wreath"]),
    ]

    private var app: XCUIApplication!
    private var step = 0

    private func record(_ name: String) {
        step += 1
        Capture.both(String(format: "s%02d-%@", step, name), app: app, in: self)
    }

    private func dismissInterruptions() {
        for label in ["Continue", "Get Started", "Close", "Not Now", "OK", "Allow"] {
            let button = app.buttons[label].firstMatch
            if button.exists && button.isHittable { button.tap(); sleep(1) }
        }
    }

    private func type(into field: XCUIElement, _ text: String, submit: Bool = false) {
        XCTAssertTrue(field.waitForExistence(timeout: 10), "missing field \(field)")
        field.tap()
        field.typeText(text + (submit ? "\n" : ""))
    }

    func testCapture() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        sleep(5)
        dismissInterruptions()
        record("launch")

        app.tabBars.buttons["Create"].tap()
        sleep(1)
        for (index, box) in samples.enumerated() {
            dismissInterruptions()
            type(into: app.textFields["Box Name"].firstMatch, box.name)
            type(into: app.textFields["New Location"].firstMatch, box.location)
            for item in box.items {
                type(into: app.textFields["New Item"].firstMatch, item, submit: true)
            }
            if index == 0 { record("create-filled") }
            if app.keyboards.count > 0 { app.swipeDown() }
            let save = app.buttons["Save"].firstMatch
            XCTAssertTrue(save.waitForExistence(timeout: 5))
            save.tap()
            sleep(3)
            if index == 0 { record("after-first-save") }
        }

        app.tabBars.buttons["Boxes"].tap()
        sleep(2)
        dismissInterruptions()
        record("boxes")

        let firstBox = app.staticTexts["Kitchen essentials"].firstMatch
        if firstBox.waitForExistence(timeout: 5) {
            firstBox.tap()
            sleep(2)
            dismissInterruptions()
            record("box-detail")
            app.swipeUp()
            sleep(1)
            record("box-detail-scrolled")
        }
    }
}
