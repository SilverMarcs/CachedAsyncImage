//
//  ImageCacher.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

// Actor for thread-safe memory cache
public actor MemoryCache {
    public static let shared = MemoryCache()
    
    #if os(macOS)
    private var cache = NSCache<NSString, NSImage>()
    #else
    private var cache = NSCache<NSString, UIImage>()
    #endif
    
    init() {
        // Initialize with default limits first
        let defaultConfig = CacheConfiguration.default
        cache.countLimit = defaultConfig.memoryCountLimit
        cache.totalCostLimit = defaultConfig.memoryCostLimit
    }
    
    private func updateCacheLimits() {
        let config = CachedAsyncImageConfiguration.shared.configuration
        cache.countLimit = config.memoryCountLimit
        cache.totalCostLimit = config.memoryCostLimit
    }
    
    #if os(macOS)
    func insert(_ image: NSImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    public func get(for key: String) -> NSImage? {
        cache.object(forKey: key as NSString)
    }
    #else
    func insert(_ image: UIImage, for key: String) {
        let bytesPerPixel = 4
        let imageSize = image.size
        let cost = Int(imageSize.width * imageSize.height * CGFloat(bytesPerPixel))
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    public func get(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    #endif
    
    public func clearCache() {
        cache.removeAllObjects()
    }
    
    /// Update cache limits from current configuration
    public func updateLimits() {
        updateCacheLimits()
    }
}
