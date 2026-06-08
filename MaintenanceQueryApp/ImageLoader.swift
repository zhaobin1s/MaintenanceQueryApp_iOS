import SwiftUI
import UIKit

/// 图片加载器（内存缓存 + 磁盘缓存）
final class ImageLoader: ObservableObject {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDir: URL

    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDir = caches.appendingPathComponent("ImageCache")
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func image(for urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }

        let cacheKey = cacheKey(for: urlString)

        // 内存缓存
        if let cached = cache.object(forKey: cacheKey as NSString) {
            return cached
        }

        // 磁盘缓存
        let diskPath = cacheDir.appendingPathComponent(cacheKey)
        if let diskData = try? Data(contentsOf: diskPath),
           let image = UIImage(data: diskData) {
            cache.setObject(image, forKey: cacheKey as NSString)
            return image
        }

        // 网络下载
        var req = URLRequest(url: url)
        req.setValue("MaintenanceQueryApp-iOS/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        req.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: req)

            // 检测 ngrok 警告页
            if let ct = (response as? HTTPURLResponse)?.allHeaderFields["Content-Type"] as? String,
               ct.lowercased().contains("html") {
                let preview = String(data: data.prefix(200), encoding: .utf8) ?? ""
                if preview.contains("ngrok") || preview.contains("html") {
                    return nil
                }
            }

            // 降采样解码，避免大图 OOM
            guard let image = downsample(data: data, maxSide: 2048) else { return nil }

            // 存入缓存
            cache.setObject(image, forKey: cacheKey as NSString)
            try? data.write(to: diskPath)

            return image
        } catch {
            return nil
        }
    }

    /// iOS 15+ 降采样（避免全分辨率解码 OOM）
    private func downsample(data: Data, maxSide: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSide
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            // 降级：直接解码
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }

    private func cacheKey(for url: String) -> String {
        // MD5 简化版
        var hash = 0
        for c in url.utf8 { hash = hash &* 31 &+ Int(c) }
        return "img_\(abs(hash))"
    }

    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDir)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
}
