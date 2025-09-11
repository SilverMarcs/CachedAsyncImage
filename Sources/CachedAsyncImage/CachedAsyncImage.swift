//
//  CachedAsyncImage.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

/// A SwiftUI view that loads and displays images asynchronously with automatic caching.
///
/// `CachedAsyncImage` provides efficient image loading with both memory and disk caching.
/// The cache can be globally configured to suit your app's needs.
///
/// ## Basic Usage
/// ```swift
/// CachedAsyncImage(
///     url: URL(string: "https://example.com/image.jpg"),
///     targetSize: CGSize(width: 200, height: 200)
/// )
/// .frame(width: 200, height: 200)
/// ```
///
/// ## Global Cache Configuration
/// Configure cache settings in your app's initialization code:
///
/// ```swift
/// // In your App.swift or AppDelegate
/// CachedAsyncImageConfiguration.configure(
///     memoryCountLimit: 150,        // Max 150 images in memory
///     memoryCostLimitMB: 100,       // Max 100 MB memory usage
///     diskCacheLimitMB: 500         // Max 500 MB disk cache
/// )
/// ```
///
/// ## Default Settings
/// - Memory: 100 images, 50 MB limit
/// - Disk: 200 MB limit
/// - Automatic cleanup when limits are exceeded
public struct CachedAsyncImage: View {
    let url: URL?
    let targetSize: CGSize

    #if os(macOS)
    @State private var image: NSImage?
    #else
    @State private var image: UIImage?
    #endif
    
    public init(url: URL?, targetSize: CGSize) {
        self.url = url
        self.targetSize = targetSize
    }

    // Convenience initializer for String URLs
    // public init(urlString: String?, targetSize: CGSize) {
    //     self.url = URL(string: urlString ?? "")
    //     self.targetSize = targetSize
    // }

    public var body: some View {
        Group {
            if let image = image {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    // .interpolation(.none)
                #else
                Image(uiImage: image)
                    .resizable()
                    // .interpolation(.none)
                #endif
            } else {
                Rectangle()
                    .fill(.background.secondary)
            }
        }
        .task(id: url) {
            if let validURL = url {
                image = try? await ImageLoader.loadAndGetImage(url: validURL, targetSize: targetSize)
            } else {
                image = nil
            }
        }
    }
}