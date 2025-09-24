//
//  ImageCacher.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

public actor MemoryCache {
    public static let shared = MemoryCache()

    #if os(macOS)
    private var cache = NSCache<NSString, NSImage>()
    #else
    private var cache = NSCache<NSString, UIImage>()
    #endif

    init() {
        let defaultConfig = CacheConfiguration.default
        cache.totalCostLimit = defaultConfig.memoryCostLimit
    }

    // Now async because it awaits the configuration actor
    public func updateLimits() async {
        let config = await CachedAsyncImageConfiguration.shared.configuration
        cache.totalCostLimit = config.memoryCostLimit
    }

    #if os(macOS)
    private func cost(for image: NSImage) -> Int {
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return cg.bytesPerRow * cg.height
        }
        let w = Int(image.size.width * 2)
        let h = Int(image.size.height * 2)
        return w * h * 4
    }
    #else
    private func cost(for image: UIImage) -> Int {
        if let cg = image.cgImage {
            return cg.bytesPerRow * cg.height
        }
        let scale = image.scale
        let w = Int(image.size.width * scale)
        let h = Int(image.size.height * scale)
        return w * h * 4
    }
    #endif

    func insert(_ image: PlatformImage, for url: URL) {
        let key = cacheKey(for: url) as NSString
        cache.setObject(image, forKey: key, cost: cost(for: image))
    }

    func get(for url: URL) -> PlatformImage? {
        cache.object(forKey: cacheKey(for: url) as NSString)
    }

    public func clearCache() {
        cache.removeAllObjects()
    }
}
