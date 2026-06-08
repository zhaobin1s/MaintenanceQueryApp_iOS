import SwiftUI

/// 主界面 — 底部导航 Tab
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showUpdateAlert = false
    @State private var updateInfo: (version: String, changelog: String, url: String)?
    @State private var isChecking = false

    var body: some View {
        TabView(selection: $selectedTab) {
            FaultQueryView()
                .tabItem {
                    Label("故障查询", systemImage: "magnifyingglass")
                }
                .tag(0)

            StepQueryView()
                .tabItem {
                    Label("生产查询", systemImage: "list.clipboard")
                }
                .tag(1)
        }
        .tint(.blue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    checkUpdate()
                } label: {
                    if isChecking {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(isChecking)
            }
        }
        .alert("发现新版本", isPresented: $showUpdateAlert, presenting: updateInfo) { info in
            Button("前往下载") {
                if let url = URL(string: info.url) {
                    UIApplication.shared.open(url)
                }
            }
            Button("稍后", role: .cancel) {}
        } message: { info in
            Text("最新版本: \(info.version)\n\n\(info.changelog)")
        }
    }

    private func checkUpdate() {
        isChecking = true
        Task {
            defer { isChecking = false }
            do {
                if let result = try await UpdateChecker.shared.check() {
                    updateInfo = (result.versionName, result.changelog, result.downloadUrl)
                    showUpdateAlert = true
                }
            } catch {}
        }
    }
}

#Preview {
    ContentView()
}
