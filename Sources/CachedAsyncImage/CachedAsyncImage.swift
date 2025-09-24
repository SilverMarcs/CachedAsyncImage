//
//  CachedAsyncImage.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

/// A SwiftUI view that loads and displays images asynchronously with automatic caching.
public struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let targetSize: Int
    let placeholder: () -> Placeholder

    #if os(macOS)
    @State private var image: NSImage?
    #else
    @State private var image: UIImage?
    #endif

    public init(
        url: URL?,
        targetSize: Int,
        @ViewBuilder placeholder: @escaping () -> Placeholder = {
            Rectangle().fill(.background.secondary)
        }
    ) {
        self.url = url
        self.targetSize = targetSize
        self.placeholder = placeholder
    }

    public var body: some View {
        Group {
            if let image = image {
                #if os(macOS)
                Image(nsImage: image).resizable()
                #else
                Image(uiImage: image).resizable()
                #endif
            } else {
                placeholder()
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
