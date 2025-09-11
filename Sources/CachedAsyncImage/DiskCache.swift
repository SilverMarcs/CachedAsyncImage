//
//  DiskCache.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import Foundation

public actor DiskCache {
    public static let shared = DiskCache()
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ImageCacher")
    }
    
    private func createCacheDirectoryIfNeeded() {
        guard let cacheDirectory = cacheDirectory else { return }
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func checkDiskCacheSize() {
        guard let cacheDirectory = cacheDirectory else { return }
        let config = CachedAsyncImageConfiguration.shared.configuration
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [])
            
            var totalSize: Int64 = 0
            var fileInfos: [(url: URL, size: Int64, date: Date)] = []
            
            for fileURL in files {
                let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                let size = Int64(attributes.fileSize ?? 0)
                let date = attributes.contentModificationDate ?? Date.distantPast
                
                totalSize += size
                fileInfos.append((url: fileURL, size: size, date: date))
            }
            
            if totalSize > config.diskCacheLimit {
                // Sort by modification date (oldest first)
                fileInfos.sort { $0.date < $1.date }
                
                // Remove oldest files until we're under the limit
                var sizeToRemove = totalSize - Int64(config.diskCacheLimit)
                for fileInfo in fileInfos {
                    if sizeToRemove <= 0 { break }
                    
                    try? fileManager.removeItem(at: fileInfo.url)
                    sizeToRemove -= fileInfo.size
                }
            }
        } catch {
            // If we can't manage the cache size, we'll just continue
            print("Failed to manage disk cache size: \(error)")
        }
    }

    func store(_ data: Data, for key: String) {
        createCacheDirectoryIfNeeded() // Check before operation
        guard let cacheDirectory = cacheDirectory else { return }
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? data.write(to: fileURL, options: .atomic)
        
        // Check cache size periodically (not on every store for performance)
        if Int.random(in: 0...10) == 0 { // Check ~10% of the time
            checkDiskCacheSize()
        }
    }
    
    func retrieve(for key: String) -> Data? {
        createCacheDirectoryIfNeeded() // Check before operation
        guard let cacheDirectory = cacheDirectory else { return nil }
        let fileURL = cacheDirectory.appendingPathComponent(key)
        return try? Data(contentsOf: fileURL)
    }
    
    public func clearCache() {
        guard let cacheDirectory = cacheDirectory else { return }
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }
    
    /// Manually check and clean disk cache to stay within size limits
    public func cleanupIfNeeded() {
        checkDiskCacheSize()
    }
}
