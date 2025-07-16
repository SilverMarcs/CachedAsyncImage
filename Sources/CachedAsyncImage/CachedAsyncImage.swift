//
//  CachedAsyncImage.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

struct CachedAsyncImage: View {
    let url: URL
    let targetSize: CGSize

    #if os(macOS)
    @State private var image: NSImage?
    #else
    @State private var image: UIImage?
    #endif

    var body: some View {
        Group {
            if let image = image {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                #else
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                #endif
            } else {
                Rectangle()
                    .fill(.secondary)
            }
        }
        .task(id: url) {
            image = try? await ImageLoader.loadAndGetImage(url: url, targetSize: targetSize)
        }
    }
}
