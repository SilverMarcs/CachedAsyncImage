//
//  ImageError.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 17/07/2025.
//

import SwiftUI

class ImageLoader {
    // Main static API for loading and caching images
    static func loadAndGetImage(url: URL, targetSize: CGSize) async throws -> PlatformImage {
        let sizeKey = "\(Int(targetSize.width))x\(Int(targetSize.height))"
        let cacheKey = "\(url.absoluteString)_\(sizeKey)"

        // Memory cache
        if let cachedImage = await MemoryCache.shared.get(for: cacheKey) {
            return cachedImage
        }

        do {
            let image: PlatformImage?

            // Disk cache
            if let diskData = await DiskCache.shared.retrieve(for: url.absoluteString) {
                image = await loadImage(from: diskData, targetSize: targetSize)
            } else {
                // Download
                let (data, _) = try await URLSession.shared.data(from: url)
                await DiskCache.shared.store(data, for: url.absoluteString)
                image = await loadImage(from: data, targetSize: targetSize)
            }

            if let finalImage = image {
                await MemoryCache.shared.insert(finalImage, for: cacheKey)
                return finalImage
            }
            throw ImageError.loadFailed
        } catch {
            throw ImageError.loadFailed
        }
    }

    // Static image decoding/downsampling
    static func loadImage(from data: Data, targetSize: CGSize) async -> PlatformImage? {
        await Task.detached(priority: .userInitiated) {
            let imageSourceOptions = [
                kCGImageSourceShouldCache: false,
                kCGImageSourceShouldAllowFloat: false
            ] as CFDictionary

            guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
                return nil
            }

            let maxDimension = min(targetSize.width, targetSize.height) * 2

            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: false,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension,
                kCGImageSourceShouldAllowFloat: false
            ] as CFDictionary

            if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
                #if os(macOS)
                return NSImage(cgImage: downsampledImage, size: NSSize(width: maxDimension, height: maxDimension))
                #else
                return UIImage(cgImage: downsampledImage, scale: 1.0, orientation: .up)
                #endif
            }

            #if os(macOS)
            return NSImage(data: data)
            #else
            return UIImage(data: data, scale: 1.0)
            #endif
        }.value
    }
}
