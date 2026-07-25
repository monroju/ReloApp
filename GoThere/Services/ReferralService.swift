import Foundation
import FirebaseAuth

/// Client for the referral Cloud Functions (getReferralCode / redeemReferral).
///
/// The app doesn't bundle the Firebase Functions SDK, so we call the callable
/// endpoints directly over HTTPS — same URLSession pattern AIService uses for the
/// AI proxy. The callable wire protocol is: POST `{ "data": {...} }` with the
/// Firebase ID token in the Authorization header; success returns
/// `{ "result": {...} }`, errors return `{ "error": { "message": ... } }`.
struct ReferralInfo {
    let code: String
    let shareURL: String
    let rewardDays: Int
}

struct RedeemResult {
    let rewardDays: Int
    let premiumUntil: Date
}

enum ReferralError: LocalizedError {
    case notSignedIn
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Create a free account (not guest mode) to invite friends and redeem codes."
        case .server(let message):
            return message
        }
    }
}

final class ReferralService {
    static let shared = ReferralService()

    // Same Cloud Functions project the IAP + AI proxy functions live in.
    private let base = "https://us-central1-gothere-e5ea7.cloudfunctions.net"

    private func callable(_ name: String, data: [String: Any]) async throws -> [String: Any] {
        guard let user = Auth.auth().currentUser else { throw ReferralError.notSignedIn }
        let token = try await user.getIDToken()

        guard let url = URL(string: "\(base)/\(name)") else {
            throw ReferralError.server("Bad function URL.")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["data": data])

        let (respData, resp) = try await URLSession.shared.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: respData)) as? [String: Any] ?? [:]

        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            let message = (json["error"] as? [String: Any])?["message"] as? String
                ?? "Something went wrong. Please try again."
            throw ReferralError.server(message)
        }
        return (json["result"] as? [String: Any]) ?? [:]
    }

    /// Returns the signed-in user's referral code, creating it on first call.
    func fetchCode() async throws -> ReferralInfo {
        let r = try await callable("getReferralCode", data: [:])
        return ReferralInfo(
            code: r["code"] as? String ?? "",
            shareURL: r["shareUrl"] as? String ?? "https://getgothere.app",
            rewardDays: r["rewardDays"] as? Int ?? 30
        )
    }

    /// Redeems a friend's code. On success the backend has already extended both
    /// users' promoAccessUntil; the caller should mirror it locally via
    /// `PurchaseManager.applyPromoGrant` for an instant UI unlock.
    func redeem(code: String) async throws -> RedeemResult {
        let r = try await callable("redeemReferral", data: ["code": code])
        let days = r["rewardDays"] as? Int ?? 30
        let ts = (r["premiumUntil"] as? TimeInterval)
            ?? Date().addingTimeInterval(Double(days) * 86_400).timeIntervalSince1970
        return RedeemResult(rewardDays: days, premiumUntil: Date(timeIntervalSince1970: ts))
    }
}
