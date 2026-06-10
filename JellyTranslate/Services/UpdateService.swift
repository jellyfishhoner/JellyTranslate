import Foundation

struct AppUpdate: Equatable {
    let version: String
    let url: URL
}

enum UpdateCheckResult: Equatable {
    case available(AppUpdate)
    case upToDate
    case failed
}

enum UpdateService {
    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: URL

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }

    static func checkForUpdate() async -> AppUpdate? {
        if case .available(let update) = await checkForUpdateResult() {
            return update
        }

        return nil
    }

    static func checkForUpdateResult() async -> UpdateCheckResult {
        guard let url = URL(string: "https://api.github.com/repos/jellyfishhoner/JellyTranslate/releases/latest") else {
            return .failed
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                return .failed
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion = normalizedVersion(release.tagName)
            guard isVersion(latestVersion, newerThan: currentVersion) else {
                return .upToDate
            }

            return .available(AppUpdate(version: latestVersion, url: release.htmlURL))
        } catch {
            return .failed
        }
    }

    private static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private static func normalizedVersion(_ version: String) -> String {
        var normalized = version.lowercased()
        if normalized.hasPrefix("v") {
            normalized.removeFirst()
        }

        return normalized
            .replacingOccurrences(of: "-alpha", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        let left = versionComponents(lhs)
        let right = versionComponents(rhs)
        let count = max(left.count, right.count)

        for index in 0..<count {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0
            if leftValue != rightValue {
                return leftValue > rightValue
            }
        }

        return false
    }

    private static func versionComponents(_ version: String) -> [Int] {
        version
            .split(separator: ".")
            .map { Int($0.filter(\.isNumber)) ?? 0 }
    }
}
