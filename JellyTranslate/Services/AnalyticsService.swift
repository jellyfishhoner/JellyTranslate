import CryptoKit
import Foundation

enum AnalyticsEvent: String {
    case appLaunched = "app_launched"
    case settingsOpened = "settings_opened"
    case quickStartOpened = "quick_start_opened"
    case historyOpened = "history_opened"
    case translationRequested = "translation_requested"
    case translationSucceeded = "translation_succeeded"
    case translationFailed = "translation_failed"
    case targetLanguageChanged = "target_language_changed"
    case replacementUsed = "replacement_used"
}

final class AnalyticsService {
    static let shared = AnalyticsService()
    static var isConfiguredForCurrentBuild: Bool {
        shared.telemetryDeckAppID.isEmpty == false && shared.telemetryDeckNamespace.isEmpty == false
    }

    private let endpointBase = "https://nom.telemetrydeck.com/v2/namespace/"
    private let userDefaultsKey = "JellyTranslate.analyticsClientID"
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 8
        session = URLSession(configuration: configuration)
    }

    func signal(_ event: AnalyticsEvent, settings: AppSettings, metadata: [String: String] = [:]) {
        guard settings.shareAnonymousAnalytics else { return }

        let appID = telemetryDeckAppID
        let namespace = telemetryDeckNamespace
        guard !appID.isEmpty, !namespace.isEmpty else {
            #if DEBUG
            print("analytics_skipped_missing_configuration event=\(event.rawValue)")
            #endif
            return
        }

        let payload = makePayload(appID: appID,
                                  event: event,
                                  settings: settings,
                                  metadata: metadata)

        Task {
            await send(payload, namespace: namespace)
        }
    }

    private var telemetryDeckAppID: String {
        (Bundle.main.object(forInfoDictionaryKey: "JellyTranslateTelemetryDeckAppID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var telemetryDeckNamespace: String {
        (Bundle.main.object(forInfoDictionaryKey: "JellyTranslateTelemetryDeckNamespace") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func makePayload(appID: String,
                             event: AnalyticsEvent,
                             settings: AppSettings,
                             metadata: [String: String]) -> [String: Any] {
        var metadata = sanitized(metadata)
        metadata["provider"] = settings.provider.shortName
        metadata["targetLanguage"] = settings.targetLanguage
        metadata["sourceLanguage"] = settings.sourceLanguage
        metadata["appLanguage"] = settings.appLanguage.rawValue
        metadata["appVersion"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        metadata["buildNumber"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        metadata["operatingSystem"] = "macOS"

        return [
            "appID": appID,
            "clientUser": anonymousUserID,
            "sessionID": sessionID,
            "type": event.rawValue,
            "payload": metadata,
            "isTestMode": isDebugBuild
        ]
    }

    private func sanitized(_ metadata: [String: String]) -> [String: String] {
        metadata.reduce(into: [:]) { result, pair in
            let key = pair.key
            guard !key.lowercased().contains("text"),
                  !key.lowercased().contains("key"),
                  !key.lowercased().contains("clipboard"),
                  !key.lowercased().contains("window") else {
                return
            }
            result[key] = String(pair.value.prefix(80))
        }
    }

    private var anonymousUserID: String {
        let rawID: String
        if let existingID = UserDefaults.standard.string(forKey: userDefaultsKey) {
            rawID = existingID
        } else {
            rawID = UUID().uuidString
            UserDefaults.standard.set(rawID, forKey: userDefaultsKey)
        }

        let digest = SHA256.hash(data: Data(rawID.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private var sessionID: String {
        SessionIDHolder.shared.id
    }

    private var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private func send(_ payload: [String: Any], namespace: String) async {
        do {
            guard let endpoint = URL(string: "\(endpointBase)\(namespace)/") else { return }
            let data = try JSONSerialization.data(withJSONObject: [payload])
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            let (_, response) = try await session.data(for: request)
            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("analytics_send_failed_status=\(httpResponse.statusCode)")
            }
            #endif
        } catch {
            #if DEBUG
            print("analytics_send_failed")
            #endif
        }
    }
}

private final class SessionIDHolder {
    static let shared = SessionIDHolder()
    let id = UUID().uuidString
}
