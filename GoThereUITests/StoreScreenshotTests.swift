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

        // Home (Tasks tab) flows. Deep links relaunch the app and drop the guest
        // session, so everything below is driven by taps.
        capture(app, lang, 10, "tasks")
        openAndCapture(app, lang, 20, "copilot", label: ["copiloto", "copilot"])
        openAndCapture(app, lang, 30, "wizard", label: ["Visa Wizard", "Asistente de visa"], steps: 4)
        openAndCapture(app, lang, 40, "compare", label: ["Compare Spain", "Comparar"])
        openAndCapture(app, lang, 50, "paywall", label: ["Mejorar plan", "Upgrade"])

        let tabs = app.tabBars.buttons
        for (i, name) in ["calendar", "documents", "resources", "decision"].enumerated() {
            let tab = tabs.element(boundBy: i + 1)
            guard tab.waitForExistence(timeout: 5) else { continue }
            tab.tap()
            sleep(2)
            capture(app, lang, 60 + i * 10, name)
            if name == "decision" {
                // Walk the Decide flow: tap the first option on each screen.
                for step in 1...6 {
                    let option = app.buttons.allElementsBoundByIndex.first {
                        $0.isHittable && $0.frame.minY > 250 && $0.frame.maxY < app.frame.maxY - 120
                    }
                    guard let option else { break }
                    option.tap()
                    sleep(2)
                    capture(app, lang, 90 + step, "decision_step")
                }
            }
        }
    }

    /// Tap the first button whose label contains any of `label`, capture the result
    /// (plus `steps` more taps on the primary/next button), then dismiss.
    private func openAndCapture(_ app: XCUIApplication, _ lang: String, _ n: Int, _ name: String,
                                label: [String], steps: Int = 0) {
        let tasksTab = app.tabBars.buttons.element(boundBy: 0)
        if tasksTab.exists { tasksTab.tap() }
        let pred = NSPredicate(format: label.map { _ in "label CONTAINS[c] %@" }.joined(separator: " OR "),
                               argumentArray: label)
        let button = app.buttons.matching(pred).firstMatch
        guard button.waitForExistence(timeout: 5) else {
            capture(app, lang, n, name + "_NOTFOUND")
            return
        }
        button.tap()
        sleep(2)
        capture(app, lang, n, name)
        if steps > 0 {
            let nextPred = NSPredicate(format:
                "label CONTAINS[c] 'next' OR label CONTAINS[c] 'siguiente' OR label CONTAINS[c] 'continu' OR label CONTAINS[c] 'start' OR label CONTAINS[c] 'empezar' OR label CONTAINS[c] 'comenzar'")
            for step in 1...steps {
                // Pick the first visible answer, then advance.
                let answer = app.buttons.allElementsBoundByIndex.first {
                    $0.isHittable && $0.frame.minY > 300 && $0.frame.maxY < app.frame.maxY - 200
                }
                answer?.tap()
                let next = app.buttons.matching(nextPred).firstMatch
                if next.exists && next.isHittable { next.tap() }
                sleep(2)
                capture(app, lang, n + step, name)
            }
        }
        dismiss(app)
    }

    private func dismiss(_ app: XCUIApplication) {
        for _ in 0..<3 {
            let close = app.buttons.matching(NSPredicate(format:
                "label IN {'Close','Cerrar','Done','Listo','Cancel','Cancelar','Atrás','Back'}")).firstMatch
            if close.exists && close.isHittable { close.tap(); sleep(1); continue }
            if app.tabBars.firstMatch.isHittable { return }
            app.swipeDown(velocity: .fast)
            sleep(1)
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
