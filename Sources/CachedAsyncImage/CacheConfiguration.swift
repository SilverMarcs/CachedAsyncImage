//
//  CacheConfiguration.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 12/09/2025.
//

import Foundation

public struct CacheConfiguration: Sendable {
    public let memoryCostLimit: Int
    public let diskCacheLimit: Int

    public static let `default` = CacheConfiguration(
        memoryCostLimit: 1024 * 1024 * 50,   // 50 MB
        diskCacheLimit: 1024 * 1024 * 200    // 200 MB
    )

    public init(
        memoryCostLimit: Int = 1024 * 1024 * 50,
        diskCacheLimit: Int = 1024 * 1024 * 200
    ) {
        self.memoryCostLimit = memoryCostLimit
        self.diskCacheLimit = diskCacheLimit
    }
}

// Actor ensures concurrency safety
public actor CachedAsyncImageConfiguration {
    public static let shared = CachedAsyncImageConfiguration()

    private var _configuration: CacheConfiguration = .default
    private var isConfigured = false

    private init() {}

    // Call once at app startup; subsequent calls are ignored
    public func configure(with configuration: CacheConfiguration) async {
        guard !isConfigured else { return }
        _configuration = configuration
        isConfigured = true

        await MemoryCache.shared.updateLimits()
        await DiskCache.shared.cleanupIfNeeded()
    }

    public var configuration: CacheConfiguration { _configuration }
}

public extension CachedAsyncImageConfiguration {
    // Convenience: fire-and-forget from sync contexts (e.g., App.init)
    static func configure(
        memoryCostLimitMB: Int = 50,
        diskCacheLimitMB: Int = 200
    ) {
        let config = CacheConfiguration(
            memoryCostLimit: memoryCostLimitMB * 1024 * 1024,
            diskCacheLimit: diskCacheLimitMB * 1024 * 1024
        )
        Task {
            await shared.configure(with: config)
        }
    }

    static func clearAllCaches() {
        Task {
            await MemoryCache.shared.clearCache()
            await DiskCache.shared.clearCache()
        }
    }
}
