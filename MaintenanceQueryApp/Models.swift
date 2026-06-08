import Foundation

// MARK: - 故障条目
struct FaultItem: Identifiable, Codable {
    let id: Int
    let name: String
    let code: String
    let model: String?
    let solution: String?
    let images: String?

    var imageList: [String] {
        guard let images = images, !images.isEmpty else { return [] }
        return images.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - 生产步骤条目
struct StepItem: Identifiable, Codable {
    let id: Int
    let name: String
    let code: String
    let model: String?
    let description: String?
    let images: String?

    var imageList: [String] {
        guard let images = images, !images.isEmpty else { return [] }
        return images.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - API 响应
struct SearchResponse: Codable {
    let results: [FaultItem]
    let count: Int
    let keyword: String
}

struct StepSearchResponse: Codable {
    let results: [StepItem]
    let count: Int
    let keyword: String
}

struct DetailResponse: Codable {
    let id: Int
    let name: String
    let code: String
    let solution: String?
    let images: String?
}

struct StepDetailResponse: Codable {
    let id: Int
    let name: String
    let code: String
    let description: String?
    let images: String?
}
