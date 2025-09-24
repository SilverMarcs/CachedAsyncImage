//
//  Utils.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 17/07/2025.
//

import Foundation
import CryptoKit
import SwiftUI

enum ImageError: Error {
    case loadFailed
    case taskCancelled
}

#if os(macOS)
typealias PlatformImage = NSImage
#else
typealias PlatformImage = UIImage
#endif

@inline(__always)
func sha256Hex(_ string: String) -> String {
    let data = Data(string.utf8)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}

@inline(__always)
func cacheKey(for url: URL) -> String {
    // For now, we hash url.absoluteString directly for stability.
    sha256Hex(url.absoluteString)
}
