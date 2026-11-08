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

        // Deep links relaunch the app and drop the guest session, so drive by taps.
        let es = lang == "es"
        capture(app, lang, 10, "tasks")
        let tabs = app.tabBars.buttons

        // Decide: a realistic profile, then results.
        tabs.element(boundBy: 4).tap()
        sleep(2)
        let profile = es
            ? ["Pareja", "Medio", "Cálido y costero", "Conocimiento básico", "Trabajo remoto"]
            : ["Couple", "Medium", "Warm & Coastal", "Basic knowledge", "Remote Work"]
        for chip in profile { tapLabel(app, chip) }
        capture(app, lang, 20, "decide_form")
        if tapLabel(app, es ? "Ver resultados" : "See Results") {
            sleep(3)
            for i in 0..<4 {
                capture(app, lang, 21 + i, "decide_results")
                app.swipeUp()
                sleep(1)
            }
        }

        // Resources tools.
        let tools: [(String, String, String)] = [
            ("cost", "¿Me alcanza para mudarme?", "Can I afford to move?"),
            ("timeline", "Armar mi calendario de mudanza", "Build my move timeline"),
            ("rights", "Derechos y seguridad", "Rights & Safety"),
            ("meds", "Medicinas y atención fuera", "Meds & Care Abroad"),
            ("start", "¿Por dónde empiezo?", "Where do I start?"),
        ]
        for (i, tool) in tools.enumerated() {
            tabs.element(boundBy: 3).tap()
            sleep(2)
            let n = 30 + i * 10
            guard tapLabel(app, es ? tool.1 : tool.2, prefix: true) else {
                capture(app, lang, n, tool.0 + "_NOTFOUND")
                continue
            }
            sleep(2)
            capture(app, lang, n, tool.0)
            app.swipeUp()
            sleep(1)
            capture(app, lang, n + 1, tool.0)
            dismiss(app)
        }
    }

    /// Tap the button whose label equals `label` (or starts with it), scrolling down
    /// until it is on screen. Returns false when it never shows up.
    @discardableResult
    private func tapLabel(_ app: XCUIApplication, _ label: String, prefix: Bool = false) -> Bool {
        let pred = prefix
            ? NSPredicate(format: "label BEGINSWITH %@", label)
            : NSPredicate(format: "label == %@", label)
        let button = app.buttons.matching(pred).firstMatch
        guard button.waitForExistence(timeout: 4) else { return false }
        for _ in 0..<8 {
            let bar = app.tabBars.firstMatch
            let limit = bar.exists ? bar.frame.minY : app.frame.maxY - 90
            if button.isHittable && button.frame.maxY <= limit {
                button.tap()
                usleep(600_000)
                return true
            }
            app.swipeUp(velocity: .slow)
        }
        return false
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
