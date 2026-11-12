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
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    private var step = 0

    private func record(_ name: String) {
        step += 1
        Capture.both(String(format: "s%02d-%@", step, name), app: app, in: self)
    }

    override func tearDownWithError() throws {
        if app != nil { record("end-state") }
    }

    private func onScreen(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        let window = app.windows.firstMatch.frame
        guard !frame.isEmpty, frame.minY >= 0, frame.maxY <= window.maxY,
              frame.minX >= 0, frame.maxX <= window.maxX else { return false }
        return element.isHittable
    }

    /// Walks onboarding pages and closes system alerts, keyboard tips and app tips.
    private func dismissInterruptions(recordPages: Bool = false) {
        let labels = ["Next", "Continue", "Get Started", "Done", "Close", "Not Now", "OK"]
        for _ in 0..<12 {
            let alertButton = springboard.alerts.buttons["Allow"].firstMatch
            if alertButton.exists {
                alertButton.tap()
                sleep(1)
                continue
            }
            guard let button = labels.lazy.map({ self.app.buttons[$0].firstMatch })
                .first(where: { self.onScreen($0) }) else { return }
            if recordPages { record("page-\(button.label)") }
            button.tap()
            sleep(2)
        }
    }

    /// Text field by placeholder, label or identifier (SwiftUI exposes the prompt as placeholder).
    private func field(_ name: String) -> XCUIElement {
        let predicate = NSPredicate(format: "placeholderValue == %@ OR label == %@ OR identifier == %@", name, name, name)
        return app.textFields.matching(predicate).firstMatch
    }

    private func replaceText(in field: XCUIElement, with text: String, submit: Bool = false) {
        XCTAssertTrue(field.waitForExistence(timeout: 10), "missing field \(field)")
        field.tap()
        dismissInterruptions()
        if !((field.value(forKey: "hasKeyboardFocus") as? Bool) ?? false) { field.tap() }
        // Typing can drop characters while the form re-renders; verify and retype.
        for _ in 0..<4 {
            let current = (field.value as? String) ?? ""
            if !current.isEmpty && current != field.placeholderValue {
                // Put the cursor after the last character before deleting backwards.
                field.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
                field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2))
            }
            for character in text {
                field.typeText(String(character))
            }
            if (field.value as? String) == text { break }
        }
        XCTAssertEqual(field.value as? String, text, "field did not take the text")
        if submit { field.typeText("\n"); sleep(1) }
    }

    private func tab(_ label: String) -> XCUIElement {
        let inTabBar = app.tabBars.buttons[label].firstMatch
        return inTabBar.exists ? inTabBar : app.buttons[label].firstMatch
    }

    func testCapture() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        sleep(5)
        dismissInterruptions(recordPages: true)
        record("launch")

        let createTab = tab("Create")
        XCTAssertTrue(createTab.waitForExistence(timeout: 10), "no Create tab after onboarding")
        createTab.tap()
        sleep(2)
        dismissInterruptions()

        for (index, box) in samples.enumerated() {
            dismissInterruptions()
            // The box title is the navigation-bar text field (pre-filled with "Box N").
            let title = app.navigationBars.textFields.firstMatch.exists
                ? app.navigationBars.textFields.firstMatch
                : app.textFields.matching(NSPredicate(format: "value BEGINSWITH 'Box'")).firstMatch
            replaceText(in: title, with: box.name, submit: false)
            replaceText(in: field("New Location"), with: box.location)
            for item in box.items {
                replaceText(in: field("New Item"), with: item, submit: true)
            }
            if index == 0 { record("create-filled") }
            let save = app.buttons["Save"].firstMatch
            XCTAssertTrue(save.waitForExistence(timeout: 5))
            save.tap()
            sleep(3)
            dismissInterruptions()
            if index == 0 { record("after-first-save") }
        }

        tab("Boxes").tap()
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
