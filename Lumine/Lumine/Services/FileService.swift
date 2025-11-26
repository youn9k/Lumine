import Foundation
import UniformTypeIdentifiers

@Observable
final class FileService {
  var files: [URL] = []

    // MARK: - Constants
    private let supportedVideoTypes: [UTType] = [.movie, .video, .quickTimeMovie, .mpeg4Movie]

    // MARK: - Persistence
    private let bookmarkKey = "FolderBookmarks"
    
    init() {
        //restoreBookmarks()
    }
    
    private func restoreBookmarks() {
        print("[FileService] Restoring bookmarks...")
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey),
              let bookmarks = try? JSONDecoder().decode([Data].self, from: data) else { return }
        
        for bookmark in bookmarks {
            var isStale = false
            do {
                var options: URL.BookmarkResolutionOptions = []
                #if os(macOS)
                options.insert(.withSecurityScope)
                #endif
                
                let url = try URL(resolvingBookmarkData: bookmark, options: options, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    print("[FileService] Bookmark is stale: \(url.path)")
                }
                
                if url.startAccessingSecurityScopedResource() {
                    print("[FileService] Restored access to: \(url.path)")
                    // Check if it's a directory or file
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                        if isDirectory.boolValue {
                            scanFolder(at: url, isRestoring: true)
                        } else {
                            // It's a file
                            if !files.contains(url) {
                                files.append(url)
                            }
                        }
                    }
                } else {
                    print("[FileService] Failed to access security scoped resource: \(url.path)")
                }
            } catch {
                print("[FileService] Error resolving bookmark: \(error)")
            }
        }
    }
    
    func addSingleFile(url: URL) {
        print("[FileService] Adding single file: \(url.path)")
        guard url.startAccessingSecurityScopedResource() else {
            print("[FileService] Failed to access security scoped resource: \(url.path)")
            return
        }
        
        saveBookmark(for: url)
        
        if !files.contains(url) {
            files.append(url)
        }
    }
    
    func scanFolder(at url: URL, isRestoring: Bool = false, recursive: Bool = false) {
        print("[FileService] Scanning folder: \(url.path) (Recursive: \(recursive))")

        // If it's a new selection (not restoring), start accessing and save bookmark
        if !isRestoring {
            guard url.startAccessingSecurityScopedResource() else {
                print("[FileService] Failed to access folder: \(url.path)")
                return
            }
            saveBookmark(for: url)
        }

        // Enumerate video files in the directory
        let videoFiles = enumerateVideoFiles(at: url, recursive: recursive)
        print("[FileService] Found \(videoFiles.count) videos in folder.")

        // Add to files list on main thread (avoid duplicates)
        DispatchQueue.main.async {
            self.addUniqueFiles(videoFiles)
        }
    }
    
    private func saveBookmark(for url: URL) {
        do {
            var options: URL.BookmarkCreationOptions = []
            #if os(macOS)
            options.insert(.withSecurityScope)
            #endif

            let bookmarkData = try url.bookmarkData(options: options, includingResourceValuesForKeys: nil, relativeTo: nil)

            // Load existing bookmarks
            var bookmarks: [Data] = []
            if let data = UserDefaults.standard.data(forKey: bookmarkKey),
               let existing = try? JSONDecoder().decode([Data].self, from: data) {
                bookmarks = existing
            }

            // Append new one if not exists
            if !bookmarks.contains(bookmarkData) {
                bookmarks.append(bookmarkData)

                // Save back
                let data = try JSONEncoder().encode(bookmarks)
                UserDefaults.standard.set(data, forKey: bookmarkKey)
                print("[FileService] Saved bookmark for: \(url.path)")
            }
        } catch {
            print("[FileService] Failed to save bookmark: \(error)")
        }
    }

    // MARK: - File Validation & Filtering

    /// Checks if the given URL points to a video file
    /// - Parameter url: The file URL to check
    /// - Returns: True if the file is a supported video type, false otherwise
    private func isVideoFile(at url: URL) -> Bool {
        guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
              let contentType = resourceValues.contentType else {
            return false
        }

        return supportedVideoTypes.contains { contentType.conforms(to: $0) }
    }

    /// Enumerates video files in a directory
    /// - Parameters:
    ///   - url: The directory URL to scan
    ///   - recursive: Whether to scan subdirectories
    /// - Returns: Array of video file URLs found in the directory
    private func enumerateVideoFiles(at url: URL, recursive: Bool) -> [URL] {
        let keys: [URLResourceKey] = [.contentTypeKey, .nameKey]
        var options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]

        if !recursive {
            options.insert(.skipsSubdirectoryDescendants)
        }

        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: options) else {
            print("[FileService] Failed to create enumerator for: \(url.path)")
            return []
        }

        var videoFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            if isVideoFile(at: fileURL) {
                videoFiles.append(fileURL)
            }
        }

        return videoFiles
    }

    /// Adds files to the files list, avoiding duplicates
    /// - Parameter newFiles: Array of file URLs to add
    private func addUniqueFiles(_ newFiles: [URL]) {
        for file in newFiles {
            if !files.contains(file) {
                files.append(file)
            }
        }
    }

    func loadFiles(from urls: [URL]) {
        print("[FileService] Loading \(urls.count) files...")

        // Filter for video files
        let videoFiles = urls.filter { url in
            let isVideo = isVideoFile(at: url)
            if !isVideo {
                print("[FileService] Skipped (not video): \(url.lastPathComponent)")
            }
            return isVideo
        }

        // Add unique files and count additions
        let initialCount = files.count
        addUniqueFiles(videoFiles)
        let addedCount = files.count - initialCount

        print("[FileService] Added \(addedCount) new files. Total: \(files.count)")
    }
    
    func clearFiles() {
        files.removeAll()
        // Note: We might want to clear bookmarks too, or keep them?
        // For now, let's keep bookmarks so they reappear on restart,
        // but user might expect "Clear" to really clear.
        // Let's clear bookmarks too for a fresh start.
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        print("[FileService] Cleared all files and bookmarks")
    }

    // MARK: - File Processing

    /// Copies a file from a source URL to the Documents directory
    /// - Parameter url: Source file URL
    /// - Returns: Destination URL if successful, nil otherwise
    private func copyFileToDocuments(from url: URL) -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let destination = documents.appendingPathComponent(url.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            // If security scoped, start accessing
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            try FileManager.default.copyItem(at: url, to: destination)
            print("[FileService] Copied file to: \(destination.lastPathComponent)")
            return destination
        } catch {
            print("[FileService] File copy error: \(error)")
            return nil
        }
    }

    /// Processes a single NSItemProvider to extract file URL
    /// - Parameter provider: The item provider to process
    /// - Returns: The extracted and copied file URL, or nil if processing failed
    private func processItemProvider(_ provider: NSItemProvider) async -> URL? {
        // Try to load as a file representation first (most reliable for drops)
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            return await withCheckedContinuation { continuation in
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
                        continuation.resume(returning: savedUrl)
                    } else {
                        if let error = error {
                            print("[FileService] Error loading movie representation: \(error)")
                        }
                        continuation.resume(returning: nil)
                    }
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            return await withCheckedContinuation { continuation in
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] url, _, error in
                    if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
                        continuation.resume(returning: savedUrl)
                    } else {
                        if let error = error {
                            print("[FileService] Error loading in-place representation: \(error)")
                        }
                        continuation.resume(returning: nil)
                    }
                }
            }
        } else if provider.canLoadObject(ofClass: URL.self) {
            return await withCheckedContinuation { continuation in
                _ = provider.loadObject(ofClass: URL.self) { [weak self] url, _ in
                    if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
                        continuation.resume(returning: savedUrl)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        } else {
            print("[FileService] Provider does not support video types: \(provider.registeredTypeIdentifiers)")
            return nil
        }
    }

    /// Processes dropped items and returns extracted file URLs (async version)
    /// - Parameter providers: Array of NSItemProvider from drop operation
    /// - Returns: Array of successfully extracted and copied file URLs
    func processDroppedItems(providers: [NSItemProvider]) async -> [URL] {
        print("[FileService] Processing \(providers.count) dropped items...")

        return await withTaskGroup(of: URL?.self) { group in
            for provider in providers {
                group.addTask {
                    await self.processItemProvider(provider)
                }
            }

            var urls: [URL] = []
            for await url in group {
                if let url = url {
                    urls.append(url)
                }
            }

            print("[FileService] Finished processing items. Found \(urls.count) valid video files.")
            return urls
        }
    }

    /// Processes dropped items and returns extracted file URLs (completion handler version)
    /// - Parameters:
    ///   - providers: Array of NSItemProvider from drop operation
    ///   - completion: Completion handler called with array of extracted URLs
    func processDroppedItems(providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        print("[FileService] Processing \(providers.count) dropped items...")
        let dispatchGroup = DispatchGroup()
        var urls: [URL] = []

        for provider in providers {
            dispatchGroup.enter()

            // Try to load as a file representation first (most reliable for drops)
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
                        urls.append(savedUrl)
                    } else if let error = error {
                        print("[FileService] Error loading movie representation: \(error)")
                    }
                    dispatchGroup.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] url, _, error in
                    if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
                        urls.append(savedUrl)
                    } else if let error = error {
                        print("[FileService] Error loading in-place representation: \(error)")
                    }
                    dispatchGroup.leave()
                }
            } else if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { [weak self] url, _ in
                    if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
                        urls.append(savedUrl)
                    }
                    dispatchGroup.leave()
                }
            } else {
                print("[FileService] Provider does not support video types: \(provider.registeredTypeIdentifiers)")
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("[FileService] Finished processing items. Found \(urls.count) valid video files.")
            completion(urls)
        }
    }
}
