import Foundation
import UIKit

/// 在线更新检查器
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    /// 当前本地版本
    static let localVersionCode = 3
    static let localVersionName = "1.1.1"

    private struct VersionResponse: Decodable {
        let version: String
        let versionCode: Int
        let downloadUrl: String
        let changelog: String?
        let forceUpdate: Bool?
    }

    /// 检查更新 — 返回 nil 表示已是最新版，否则返回更新信息
    func check() async throws -> (versionName: String, changelog: String, downloadUrl: String)? {
        guard let url = URL(string: "https://startup-sepia-oblivion.ngrok-free.dev/api/version") else {
            throw UpdateError.invalidURL
        }

        var req = URLRequest(url: url)
        req.setValue("MaintenanceQueryApp-iOS/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        req.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw UpdateError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let decoder = JSONDecoder()
        let info = try decoder.decode(VersionResponse.self, from: data)

        if info.versionCode > Self.localVersionCode {
            return (
                versionName: info.version,
                changelog: info.changelog ?? "无更新说明",
                downloadUrl: info.downloadUrl
            )
        }

        return nil
    }
}

enum UpdateError: LocalizedError {
    case invalidURL
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的检查地址"
        case .httpError(let code): return "检查更新失败: HTTP \(code)"
        }
    }
}
