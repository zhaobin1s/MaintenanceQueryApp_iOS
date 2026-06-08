import Foundation
import UIKit

/// 服务端配置
struct ServerConfig {
    /// ngrok 公网地址（尾部不含 /）
    static let baseURL = "https://startup-sepia-oblivion.ngrok-free.dev"

    /// 构建完整 API URL
    static func url(_ path: String, params: [String: String] = [:]) -> URL? {
        guard var components = URLComponents(string: baseURL + path) else { return nil }
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url
    }
}

// MARK: - API 服务
final class APIService {
    static let shared = APIService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: 故障搜索
    func searchFaults(keyword: String, model: String? = nil) async throws -> SearchResponse {
        var params = ["keyword": keyword]
        if let model = model, !model.isEmpty { params["model"] = model }

        guard let url = ServerConfig.url("/api/search", params: params) else {
            throw APIError.invalidURL
        }
        return try await request(url)
    }

    // MARK: 故障详情
    func getFaultDetail(code: String) async throws -> DetailResponse {
        guard let url = ServerConfig.url("/api/detail", params: ["code": code]) else {
            throw APIError.invalidURL
        }
        return try await request(url)
    }

    // MARK: 生产步骤搜索
    func searchSteps(keyword: String, model: String? = nil) async throws -> StepSearchResponse {
        var params = ["keyword": keyword]
        if let model = model, !model.isEmpty { params["model"] = model }

        guard let url = ServerConfig.url("/api/steps/search", params: params) else {
            throw APIError.invalidURL
        }
        return try await request(url)
    }

    // MARK: 生产步骤详情
    func getStepDetail(code: String) async throws -> StepDetailResponse {
        guard let url = ServerConfig.url("/api/steps/detail", params: ["code": code]) else {
            throw APIError.invalidURL
        }
        return try await request(url)
    }

    // MARK: 通用请求
    private func request<T: Decodable>(_ url: URL) async throws -> T {
        var req = URLRequest(url: url)
        req.setValue("MaintenanceQueryApp-iOS/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await session.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodeError(error)
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodeError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的请求地址"
        case .invalidResponse: return "服务器无响应"
        case .httpError(let code): return "HTTP \(code)"
        case .decodeError(let e): return "数据解析失败: \(e.localizedDescription)"
        }
    }
}
