//
//  ImageError.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 17/07/2025.
//

import SwiftUI
import ImageIO

class ImageLoader {
    static func loadAndGetImage(url: URL, targetSize: Int) async throws -> PlatformImage {
        // Try memory cache first
        if let cachedImage = await MemoryCache.shared.get(for: url) {
            // Optional upgrade: re-decode if cached is smaller than requested.
            let cachedMax = pixelMaxDimension(of: cachedImage)
            if cachedMax >= targetSize {
                return cachedImage
            }
            // else continue to decode a larger version and replace
        }

        do {
            let image: PlatformImage?

            // Disk cache: original data by URL (hashing internal to DiskCache)
            if let diskData = await DiskCache.shared.retrieve(for: url) {
                image = await loadImage(from: diskData, maxPixelSize: targetSize)
            } else {
                // Download and persist
                let (data, _) = try await URLSession.shared.data(from: url)
                await DiskCache.shared.store(data, for: url)
                image = await loadImage(from: data, maxPixelSize: targetSize)
            }

            if let finalImage = image {
                await MemoryCache.shared.insert(finalImage, for: url)
                return finalImage
            }
            throw ImageError.loadFailed
        } catch {
            throw ImageError.loadFailed
        }
    }

    static func loadImage(from data: Data, maxPixelSize: Int) async -> PlatformImage? {
        await Task.detached(priority: .userInitiated) {
            let imageSourceOptions = [
                kCGImageSourceShouldCache: false,
                kCGImageSourceShouldAllowFloat: false
            ] as CFDictionary

            guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
                return nil
            }

            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: false,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize, 1),
                kCGImageSourceShouldAllowFloat: false
            ] as CFDictionary

            if let thumb = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
                #if os(macOS)
                return NSImage(cgImage: thumb, size: .zero)
                #else
                return UIImage(cgImage: thumb, scale: 1.0, orientation: .up)
                #endif
            }

            #if os(macOS)
            return NSImage(data: data)
            #else
            return UIImage(data: data, scale: 1.0)
            #endif
        }.value
    }

    // Helpers

    #if os(macOS)
    private static func pixelMaxDimension(of image: NSImage) -> Int {
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return max(cg.width, cg.height)
        }
        let approx = max(Int(image.size.width), Int(image.size.height)) * 2
        return approx
    }
    #else
    private static func pixelMaxDimension(of image: UIImage) -> Int {
        let w = image.size.width * image.scale
        let h = image.size.height * image.scale
        return Int(max(w, h))
    }
    #endif
}
