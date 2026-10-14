import Foundation
import AdServices

/// Resolves where this install came from, once, and fires `install_attributed`.
///
/// Apple Ads: the AdServices token is posted to Apple's attribution API, which answers
/// with campaign / ad group / keyword ids. No ATT prompt is needed for this payload.
/// Anything else is `organic` (App Store `ct` campaign links are only visible in ASC
/// Analytics, not in the app). The token is only valid for 24 h, so after a day of
/// failed attempts the install is recorded as `unknown` and we stop trying.
enum InstallAttribution {
    private static let doneKey = "install_attributed_v1"
    private static let sourceKey = "acq_source_v1"
    private static let firstTryKey = "install_attribution_first_try_at"
    private static let endpoint = URL(string: "https://api-adservices.apple.com/api/v1/")!

    static var storedSource: String {
        UserDefaults.standard.string(forKey: sourceKey) ?? "pending"
    }

    /// Call at launch, after PostHog setup. No-op once attribution has been recorded.
    static func resolveOnce() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: doneKey) else { return }
        if defaults.object(forKey: firstTryKey) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: firstTryKey)
        }
        let firstTry = defaults.double(forKey: firstTryKey)

        Task.detached(priority: .utility) {
            var props: [String: Any]
            if let token = try? AAAttribution.attributionToken() {
                guard let payload = await fetch(token: token) else {
                    // Network or Apple not ready yet: try again next launch while the token can still resolve.
                    if Date().timeIntervalSince1970 - firstTry < 24 * 3600 { return }
                    props = ["acq_source": "unknown"]
                    record(props)
                    return
                }
                if payload["attribution"] as? Bool == true {
                    props = ["acq_source": "asa"]
                    for (key, name) in [("campaignId", "campaign_id"), ("adGroupId", "adgroup_id"),
                                        ("keywordId", "keyword_id"), ("adId", "ad_id"),
                                        ("countryOrRegion", "country"), ("conversionType", "conversion_type")] {
                        if let value = payload[key] { props[name] = "\(value)" }
                    }
                } else {
                    props = ["acq_source": "organic"]
                }
            } else {
                // Simulator, or AdServices unavailable.
                props = ["acq_source": "unknown"]
            }
            record(props)
        }
    }

    private static func record(_ props: [String: Any]) {
        let source = props["acq_source"] as? String ?? "unknown"
        UserDefaults.standard.set(source, forKey: sourceKey)
        UserDefaults.standard.set(true, forKey: doneKey)
        Analytics.setAcquisitionSource(source)
        var withSet = props
        withSet["$set_once"] = ["acq_source": source]
        Analytics.log(.installAttributed, properties: withSet)
    }

    /// Apple returns 404 for a few seconds after first launch while the record is prepared;
    /// retry 3 times, 5 s apart, as Apple recommends.
    private static func fetch(token: String) async -> [String: Any]? {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(token.utf8)
        request.timeoutInterval = 15
        for attempt in 0..<3 {
            if attempt > 0 { try? await Task.sleep(nanoseconds: 5_000_000_000) }
            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  let status = (response as? HTTPURLResponse)?.statusCode else { continue }
            if status == 200 {
                return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            }
            if status != 404 { return nil }
        }
        return nil
    }
}
