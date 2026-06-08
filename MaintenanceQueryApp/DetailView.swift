import SwiftUI

/// 详情页（故障详情 / 生产步骤详情）
struct DetailView: View {
    let code: String
    let name: String
    let isStep: Bool

    @State private var solutionText: String?
    @State private var imagePaths: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载中...")
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 标题卡片
                        VStack(alignment: .leading, spacing: 8) {
                            Text(name)
                                .font(.title2)
                                .fontWeight(.bold)

                            HStack {
                                Text(code)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(isStep ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                                    .foregroundColor(isStep ? .green : .blue)
                                    .cornerRadius(6)
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                        // 方案文本
                        if let solution = solutionText, !solution.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(isStep ? "操作说明" : "解决方案")
                                    .font(.headline)

                                Text(solution)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }

                        // 图片列表
                        if !imagePaths.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("参考图片（\(imagePaths.count)张）")
                                    .font(.headline)

                                LazyVStack(spacing: 12) {
                                    ForEach(imagePaths.indices, id: \.self) { idx in
                                        let fullURL = ServerConfig.baseURL + "/" + imagePaths[idx].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                                        AsyncImageView(urlString: fullURL)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }
                    }
                    .padding(16)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetail() }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            if isStep {
                let detail = try await APIService.shared.getStepDetail(code: code)
                await MainActor.run {
                    solutionText = cleanText(detail.description)
                    imagePaths = detail.imageList
                    isLoading = false
                }
            } else {
                let detail = try await APIService.shared.getFaultDetail(code: code)
                await MainActor.run {
                    solutionText = cleanText(detail.solution)
                    imagePaths = detail.imageList
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    /// 清洗文本：去除 Markdown 标记
    private func cleanText(_ text: String?) -> String? {
        guard let text = text, !text.isEmpty else { return nil }
        var cleaned = text
        // 去粗体
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        // 去链接标记 [text](url) → text
        let linkPattern = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\([^\\)]+\\)", options: [])
        cleaned = linkPattern?.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "$1") ?? cleaned
        // 去多余空行
        while cleaned.contains("\n\n\n") {
            cleaned = cleaned.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 异步图片子视图
struct AsyncImageView: View {
    let urlString: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var failed = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if failed || image == nil {
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("图片加载失败")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                Image(uiImage: image!)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
            }
        }
        .task {
            if let img = await ImageLoader.shared.image(for: urlString) {
                await MainActor.run {
                    image = img
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    failed = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(code: "不通电", name: "电源不通电", isStep: false)
    }
}
