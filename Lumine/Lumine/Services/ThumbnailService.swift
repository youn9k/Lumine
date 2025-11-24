import AVFoundation
import Foundation
import SwiftUI

#if os(macOS)
  import AppKit

  typealias PlatformImage = NSImage
#else
  import UIKit

  typealias PlatformImage = UIImage
#endif

actor ThumbnailService {
  static let shared = ThumbnailService()

  private let cache = NSCache<NSURL, PlatformImage>()
  private var pendingRequests: [URL: Task<PlatformImage?, Error>] = [:]

  private init() {
    //cache.countLimit = 100 // Limit to 100 thumbnails
  }

  func generateThumbnail(for url: URL) async throws -> PlatformImage? {
    // Check cache first
    if let cachedImage = cache.object(forKey: url as NSURL) {
      return cachedImage
    }

    // Check if there's already a pending request for this URL
    if let existingTask = pendingRequests[url] {
      return try await existingTask.value
    }

    // Create a new task
    let task = Task<PlatformImage?, Error> {
      let asset = AVAsset(url: url)
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      generator.requestedTimeToleranceAfter = CMTime(seconds: 5, preferredTimescale: 60)
      
      // Generate thumbnail at 1 second or start
      let time = CMTime(seconds: 1, preferredTimescale: 60)

      do {
        let cgImage = try await generator.image(at: time).image

        #if os(macOS)
          let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #else
          let image = UIImage(cgImage: cgImage)
        #endif

        cache.setObject(image, forKey: url as NSURL)
        return image
      } catch {
        print("[ThumbnailService] Failed to generate thumbnail for \(url.lastPathComponent): \(error)")
        throw error
      }
    }

    pendingRequests[url] = task

    do {
      let image = try await task.value
      pendingRequests[url] = nil
      return image
    } catch {
      pendingRequests[url] = nil
      throw error
    }
  }
}
