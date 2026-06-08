# MaintenanceQueryApp iOS 版

## 文件清单

| 文件 | 说明 |
|------|------|
| `MaintenanceQueryApp.swift` | App 入口 |
| `ContentView.swift` | 底部 Tab 导航（故障查询 / 生产查询） |
| `FaultQueryView.swift` | 故障查询页（搜索 + 结果列表） |
| `StepQueryView.swift` | 生产步骤查询页（搜索 + 结果列表） |
| `DetailView.swift` | 详情页（标题卡片 + 方案文本 + 图片列表） |
| `Models.swift` | 数据模型 |
| `APIService.swift` | API 服务层（对接 Flask 后端） |
| `ImageLoader.swift` | 图片加载器（内存缓存 + 磁盘缓存 + 降采样） |
| `Info.plist` | 应用配置（含 ATS 例外允许 ngrok 自签名证书） |

## Xcode 项目创建步骤

1. **创建项目**：Xcode → New Project → iOS App
   - Interface: SwiftUI
   - Language: Swift
   - Organization Identifier 随意（如 `com.maintenance.query`）

2. **删除自动生成的 ContentView.swift**

3. **拖入本目录所有 `.swift` 文件到 Xcode 项目**

4. **替换 Info.plist**：用本目录的 Info.plist 替换项目自动生成的

5. **最低部署目标**：iOS 16.0+（AsyncImage / NavigationStack 等 API 要求）

6. **编译运行**：Cmd+R

## 与 Android 版的差异

| 项目 | Android | iOS |
|------|---------|-----|
| 图片缓存 | LruCache + 磁盘 | NSCache + 磁盘 |
| 图片解码 | BitmapFactory + 降采样 | CGImageSource 降采样 |
| SSL 信任 | 全信任 TrustManager | Info.plist ATS 例外 |
| 请求头 | User-Agent + ngrok-skip-browser-warning | 同 |
| API | 同一套后端 API | 同 |
