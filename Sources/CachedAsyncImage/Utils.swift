//
//  Utils.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 17/07/2025.
//

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
