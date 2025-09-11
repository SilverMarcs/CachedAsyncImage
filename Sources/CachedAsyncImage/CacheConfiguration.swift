//
//  CacheConfiguration.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 12/09/2025.
//

import Foundation

/// Configuration settings for the cached async image system
public struct CacheConfiguration: Sendable {
    /// Maximum number of images to keep in memory cache
    public let memoryCountLimit: Int
    
    /// Maximum total cost (in bytes) for memory cache (approximate)
    public let memoryCostLimit: Int
    
    /// Maximum disk cache size in bytes
    public let diskCacheLimit: Int
    
    /// Default configuration with reasonable defaults
    public static let `default` = CacheConfiguration(
        memoryCountLimit: 100,
        memoryCostLimit: 1024 * 1024 * 50, // 50 MB
        diskCacheLimit: 1024 * 1024 * 200   // 200 MB
    )
    
    /// Initialize with custom cache limits
    /// - Parameters:
    ///   - memoryCountLimit: Maximum number of images in memory (default: 100)
    ///   - memoryCostLimit: Maximum memory usage in bytes (default: 50MB)
    ///   - diskCacheLimit: Maximum disk cache size in bytes (default: 200MB)
    public init(
        memoryCountLimit: Int = 100,
        memoryCostLimit: Int = 1024 * 1024 * 50,
        diskCacheLimit: Int = 1024 * 1024 * 200
    ) {
        self.memoryCountLimit = memoryCountLimit
        self.memoryCostLimit = memoryCostLimit
        self.diskCacheLimit = diskCacheLimit
    }
}

/// Global configuration manager for the cached async image system
public final class CachedAsyncImageConfiguration: @unchecked Sendable {
    /// Shared configuration instance
    public static let shared = CachedAsyncImageConfiguration()
    
    /// Current cache configuration
    private var _configuration: CacheConfiguration = .default
    
    /// Thread-safe access to configuration
    private let configurationQueue = DispatchQueue(label: "CachedAsyncImageConfiguration.queue", attributes: .concurrent)
    
    private init() {}
    
    /// Configure the global cache settings
    /// - Parameter configuration: The cache configuration to use
    /// - Note: This should typically be called once during app initialization
    public func configure(with configuration: CacheConfiguration) {
        configurationQueue.async(flags: .barrier) {
            self._configuration = configuration
            
            // Update existing cache instances with new limits
            Task {
                await MemoryCache.shared.updateLimits()
                await DiskCache.shared.cleanupIfNeeded()
            }
        }
    }
    
    /// Get the current configuration (thread-safe)
    public var configuration: CacheConfiguration {
        configurationQueue.sync {
            return _configuration
        }
    }
}

/// Public convenience methods for configuring the cache
public extension CachedAsyncImageConfiguration {
    /// Configure cache with custom memory and disk limits
    /// - Parameters:
    ///   - memoryCountLimit: Maximum number of images in memory
    ///   - memoryCostLimitMB: Maximum memory usage in megabytes
    ///   - diskCacheLimitMB: Maximum disk cache size in megabytes
    static func configure(
        memoryCountLimit: Int = 100,
        memoryCostLimitMB: Int = 50,
        diskCacheLimitMB: Int = 200
    ) {
        let config = CacheConfiguration(
            memoryCountLimit: memoryCountLimit,
            memoryCostLimit: memoryCostLimitMB * 1024 * 1024,
            diskCacheLimit: diskCacheLimitMB * 1024 * 1024
        )
        shared.configure(with: config)
    }
    
    /// Clear all cached images from both memory and disk
    static func clearAllCaches() {
        Task {
            await MemoryCache.shared.clearCache()
            await DiskCache.shared.clearCache()
        }
    }
}