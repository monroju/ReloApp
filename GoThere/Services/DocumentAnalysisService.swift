import Foundation

/// Structured result from the `analyzeDocument` Cloud Function. Mirrors the
/// report_document tool schema (snake_case on the wire → camelCase here via
/// `.convertFromSnakeCase`).
struct DocumentAnalysis: Decodable {
    var unreadable: Bool
    var isDocument: Bool
    var docType: String?
    var category: String?
    var sender: String?
    var originalLanguage: String?
    var confidence: String?
    var summary: String?
    var nextStep: String?
    var deadlines: [Deadline]

    struct Deadline: Decodable {
        var dateIso: String?
        var dateAsWritten: String
        var sourceQuote: String
        var action: String
    }

    private enum CodingKeys: String, CodingKey {
        case unreadable, isDocument, docType, category, sender
        case originalLanguage, confidence, summary, nextStep, deadlines
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        unreadable = (try? c.decode(Bool.self, forKey: .unreadable)) ?? false
        isDocument = (try? c.decode(Bool.self, forKey: .isDocument)) ?? true
        docType = try? c.decode(String.self, forKey: .docType)
        category = try? c.decode(String.self, forKey: .category)
        sender = try? c.decode(String.self, forKey: .sender)
        originalLanguage = try? c.decode(String.self, forKey: .originalLanguage)
        confidence = try? c.decode(String.self, forKey: .confidence)
        // Trim whitespace + any stray wrapping quote the model occasionally emits.
        summary = (try? c.decode(String.self, forKey: .summary)).map(Self.clean)
        nextStep = (try? c.decode(String.self, forKey: .nextStep)).map(Self.clean)
        deadlines = (try? c.decode([Deadline].self, forKey: .deadlines)) ?? []
    }

    private static func clean(_ s: String) -> String {
        s.trimmingCharacters(in: CharacterSet(charactersIn: " \n\t\"'"))
    }
}

enum DocumentAnalysisError: LocalizedError {
    case server(String)
    case decoding
    var errorDescription: String? {
        switch self {
        case .server(let m): return m
        case .decoding: return "Couldn't read the response. Please try again."
        }
    }
}

/// One-shot document scanner: photo/PDF → structured plain-English explanation via
/// the `analyzeDocument` function. Also owns the free-scan quota gate, mirroring
/// `AIService`'s free-message pattern (separate counter, same entitlement source).
@MainActor
final class DocumentAnalysisService: ObservableObject {

    /// Free scans before the paywall gate. Documents are higher-value per use than
    /// chat turns, so a smaller free allowance than AI messages.
    static let maxFreeScans = 3

    static let shared = DocumentAnalysisService(purchaseManager: PurchaseManager.shared)

    /// Endpoint. Override-able via UserDefaults for QA, like AIService.proxyURL.
    static let endpoint: URL = {
        if let override = UserDefaults.standard.string(forKey: "doc_analysis_url_override"),
           let url = URL(string: override) {
            return url
        }
        return URL(string: "https://us-central1-gothere-e5ea7.cloudfunctions.net/analyzeDocument")!
    }()

    @Published var scanCount: Int
    @Published var isAnalyzing = false

    private let purchaseManager: PurchaseManager
    private let session: URLSession
    private let counterKey = "doc_scan_count"

    init(purchaseManager: PurchaseManager, session: URLSession = .shared) {
        self.purchaseManager = purchaseManager
        self.session = session
        self.scanCount = UserDefaults.standard.integer(forKey: counterKey)
    }

    // MARK: - Paywall gate

    /// True when free scans are used up and the user isn't entitled to all-access.
    var isScanGated: Bool {
        scanCount >= Self.maxFreeScans && !purchaseManager.hasAllAccess
    }

    var remainingFreeScans: Int {
        max(0, Self.maxFreeScans - scanCount)
    }

    func resetScanCounter() {
        scanCount = 0
        UserDefaults.standard.set(0, forKey: counterKey)
    }

    // MARK: - Analysis

    /// Sends a (already JPEG-compressed) image to the analyzer and returns the
    /// structured reading. Increments the free-scan counter on a successful,
    /// readable result. Caller must check `isScanGated` first and present the
    /// paywall if needed.
    func analyze(imageData: Data, mediaType: String = "image/jpeg", country: String? = nil) async throws -> DocumentAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }

        var payload: [String: Any] = [
            "image": ["media_type": mediaType, "data": imageData.base64EncodedString()]
        ]
        if let country, !country.isEmpty { payload["country"] = country }

        var req = URLRequest(url: Self.endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(AIService.appToken, forHTTPHeaderField: "X-GoThere-App-Token")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw DocumentAnalysisError.server(msg ?? "The document reader is unavailable right now. Please try again.")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let result = try? decoder.decode(DocumentAnalysis.self, from: data) else {
            throw DocumentAnalysisError.decoding
        }

        // Only spend a free scan when we actually read a document.
        if !result.unreadable {
            scanCount += 1
            UserDefaults.standard.set(scanCount, forKey: counterKey)
        }
        return result
    }
}
