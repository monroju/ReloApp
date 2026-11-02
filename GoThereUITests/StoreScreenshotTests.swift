import XCTest

/// Captures App Store screenshots in Spanish and English on the CI simulator.
/// Run by the Codemagic `ios-screenshots` workflow only. Every capture is saved as a
/// kept attachment ("<lang>_<nn>_<name>"), together with a text dump of the UI tree
/// so the flow can be tuned without a local Mac.
final class StoreScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    func testSpanish() { run(lang: "es", locale: "es_MX") }
    func testEnglish() { run(lang: "en", locale: "en_US") }

    private func run(lang: String, locale: String) {
        let app = XCUIApplication()
        app.launchArguments += [
            "-GTScreenshots",
            "-AppleLanguages", "(\(lang))",
            "-AppleLocale", locale,
        ]
        addUIInterruptionMonitor(withDescription: "system alerts") { alert in
            for label in ["Don’t Allow", "Don't Allow", "No permitir", "Allow", "Permitir", "OK", "Aceptar"] {
                let b = alert.buttons[label]
                if b.exists { b.tap(); return true }
            }
            return false
        }
        app.launch()
        sleep(3)
        capture(app, lang, 0, "launch")

        // Login screen: enter as guest (label is localized, match both).
        let guest = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'guest' OR label CONTAINS[c] 'invitado'")).firstMatch
        if guest.waitForExistence(timeout: 5) {
            guest.tap()
            sleep(3)
            capture(app, lang, 1, "after_guest")
        }

        let routes = ["tasks", "calendar", "documents", "resources", "decision", "wizard"]
        for (i, route) in routes.enumerated() {
            if let url = URL(string: "gothere://\(route)") {
                app.open(url)
            }
            sleep(3)
            capture(app, lang, 10 + i, route)
        }
    }

    private func capture(_ app: XCUIApplication, _ lang: String, _ n: Int, _ name: String) {
        let base = String(format: "%@_%02d_%@", lang, n, name)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = base
        shot.lifetime = .keepAlways
        add(shot)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = base + "_tree"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
