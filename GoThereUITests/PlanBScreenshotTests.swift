import XCTest

/// Plan B store screenshot (Codemagic `ios-screenshots` on ci/screenshots-planb).
/// The app seeds one Ireland grandparent path at about 60 readiness (-GTSeedPlanB, DEBUG only)
/// and opens on the Plan B tab. Captures are kept attachments named "<lang>_<nn>_<name>".
final class PlanBScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    func testPlanBEnglish() { run(lang: "en", locale: "en_US") }
    func testPlanBSpanish() { run(lang: "es", locale: "es_MX") }

    private func run(lang: String, locale: String) {
        let app = XCUIApplication()
        app.launchArguments += ["-GTScreenshots", "-GTSeedPlanB",
                                "-AppleLanguages", "(\(lang))", "-AppleLocale", locale]
        addUIInterruptionMonitor(withDescription: "system alerts") { alert in
            for label in ["Don’t Allow", "Don't Allow", "No permitir", "OK", "Aceptar"] {
                let b = alert.buttons[label]
                if b.exists { b.tap(); return true }
            }
            return false
        }
        app.launch()
        sleep(3)
        let guest = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'guest' OR label CONTAINS[c] 'invitado'")).firstMatch
        if guest.waitForExistence(timeout: 5) {
            guest.tap()
            sleep(3)
        }
        let tab = app.tabBars.buttons["Plan B"]
        if tab.waitForExistence(timeout: 5) { tab.tap() }
        sleep(2)
        capture(app, lang, 60, "planb")
        app.swipeUp()
        sleep(1)
        capture(app, lang, 61, "planb_scrolled")
        app.swipeDown()
        sleep(1)
        // First tracked path row opens the document checklist.
        let row = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'Ireland' OR label CONTAINS[c] 'Irlanda'")).firstMatch
        if row.waitForExistence(timeout: 4) {
            row.tap()
            sleep(2)
            capture(app, lang, 62, "planb_detail")
        } else {
            capture(app, lang, 62, "planb_detail_NOTFOUND")
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
