import XCTest

/// Saves screenshots and accessibility dumps to SHOT_DIR (passed as TEST_RUNNER_SHOT_DIR).
enum Capture {
    static var dir: URL {
        let path = ProcessInfo.processInfo.environment["SHOT_DIR"] ?? NSTemporaryDirectory()
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func shot(_ name: String, in test: XCTestCase) {
        let screenshot = XCUIScreen.main.screenshot()
        try? screenshot.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
    }

    static func dump(_ name: String, app: XCUIApplication) {
        let text = app.debugDescription
        try? text.write(to: dir.appendingPathComponent("\(name).txt"), atomically: true, encoding: .utf8)
    }

    static func both(_ name: String, app: XCUIApplication, in test: XCTestCase) {
        shot(name, in: test)
        dump(name, app: app)
    }
}
