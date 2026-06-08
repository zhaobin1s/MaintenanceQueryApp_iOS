import SwiftUI

/// 故障查询页面
struct FaultQueryView: View {
    @State private var keyword = ""
    @State private var model = ""
    @State private var results: [FaultItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        TextField("故障代码或关键词", text: $keyword)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()

                        TextField("型号（可选）", text: $model)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .autocorrectionDisabled()

                        Button(action: search) {
                            Text("搜索")
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        .disabled(keyword.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))

                // 内容区
                if isLoading {
                    Spacer()
                    ProgressView("搜索中...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("输入关键词搜索故障")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(results) { item in
                        NavigationLink(destination: DetailView(code: item.code, name: item.name, isStep: false)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                HStack {
                                    Text(item.code)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                    if let model = item.model, !model.isEmpty {
                                        Text(model)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("故障查询")
        }
    }

    private func search() {
        let kw = keyword.trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        results = []

        Task {
            do {
                let response = try await APIService.shared.searchFaults(keyword: kw, model: model.trimmingCharacters(in: .whitespaces))
                await MainActor.run {
                    results = response.results
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    FaultQueryView()
}
