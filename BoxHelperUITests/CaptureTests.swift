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

    /// Walks the onboarding pages and closes tips or alerts, recording each page once.
    private func dismissInterruptions(recordPages: Bool = false) {
        let labels = ["Next", "Continue", "Get Started", "Let's Go", "Start", "Done", "Close", "Not Now", "OK", "Allow"]
        for _ in 0..<12 {
            guard let button = labels.lazy.map({ self.app.buttons[$0].firstMatch })
                .first(where: { $0.exists && $0.isHittable }) else { return }
            if recordPages { record("onboarding-\(button.label)") }
            button.tap()
            sleep(2)
        }
    }

    override func tearDownWithError() throws {
        if app != nil { record("end-state") }
    }

    /// Text field by placeholder, label or identifier (SwiftUI exposes the prompt as placeholder).
    private func field(_ name: String) -> XCUIElement {
        let predicate = NSPredicate(format: "placeholderValue == %@ OR label == %@ OR identifier == %@", name, name, name)
        return app.textFields.matching(predicate).firstMatch
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
        dismissInterruptions(recordPages: true)
        record("launch")

        let createTab = app.tabBars.buttons["Create"].firstMatch
        XCTAssertTrue(createTab.waitForExistence(timeout: 10), "no Create tab after onboarding")
        createTab.tap()
        sleep(1)
        for (index, box) in samples.enumerated() {
            dismissInterruptions()
            type(into: field("Box Name"), box.name)
            type(into: field("New Location"), box.location)
            for item in box.items {
                type(into: field("New Item"), item, submit: true)
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
