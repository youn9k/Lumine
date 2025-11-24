import Foundation
import UniformTypeIdentifiers

@Observable
final class FileService {
  var files: [URL] = []

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
                    // In a real app, you might want to re-save the bookmark here
                }
                
                if url.startAccessingSecurityScopedResource() {
                    print("[FileService] Restored access to: \(url.path)")
                    scanFolder(at: url, isRestoring: true)
                } else {
                    print("[FileService] Failed to access security scoped resource: \(url.path)")
                }
            } catch {
                print("[FileService] Error resolving bookmark: \(error)")
            }
        }
    }
    
    func scanFolder(at url: URL, isRestoring: Bool = false) {
        print("[FileService] Scanning folder: \(url.path)")
        
        // If it's a new selection (not restoring), start accessing
        if !isRestoring {
            guard url.startAccessingSecurityScopedResource() else {
                print("[FileService] Failed to access folder: \(url.path)")
                return
            }
            saveBookmark(for: url)
        }
        
        let keys: [URLResourceKey] = [.contentTypeKey, .nameKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
        
        // Create enumerator for recursive scanning
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: options) else {
            print("[FileService] Failed to create enumerator for: \(url.path)")
            return
        }
        
        var newFiles: [URL] = []
        let videoTypes: [UTType] = [.movie, .video, .quickTimeMovie, .mpeg4Movie]
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)),
                  let contentType = resourceValues.contentType else { continue }
            
            if videoTypes.contains(where: { contentType.conforms(to: $0) }) {
                newFiles.append(fileURL)
            }
        }
        
        print("[FileService] Found \(newFiles.count) videos in folder.")
        
        // Add to files list (avoid duplicates)
        DispatchQueue.main.async {
            for file in newFiles {
                if !self.files.contains(file) {
                    self.files.append(file)
                }
            }
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

    func loadFiles(from urls: [URL]) {
        print("[FileService] Loading \(urls.count) files...")
        // Filter for video files
        let videoTypes: [UTType] = [.movie, .video, .quickTimeMovie, .mpeg4Movie]
        
        let newFiles = urls.filter { url in
            guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
                  let contentType = resourceValues.contentType else {
                print("[FileService] Skipped (unknown type): \(url.lastPathComponent)")
                return false
            }
            let isVideo = videoTypes.contains { contentType.conforms(to: $0) }
            if !isVideo {
                print("[FileService] Skipped (not video): \(url.lastPathComponent) (\(contentType.identifier))")
            }
            return isVideo
        }
        
        // Append unique files
        var addedCount = 0
        for file in newFiles {
            if !files.contains(file) {
                files.append(file)
                addedCount += 1
            }
        }
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
    
    func processDroppedItems(providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        print("[FileService] Processing \(providers.count) dropped items...")
        let dispatchGroup = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            dispatchGroup.enter()
            
            // Helper to copy file to Documents
            func copyFile(from url: URL) -> URL? {
                guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
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
            
            // Try to load as a file representation first (most reliable for drops)
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let url = url, let savedUrl = copyFile(from: url) {
                        urls.append(savedUrl)
                    } else if let error = error {
                        print("[FileService] Error loading movie representation: \(error)")
                    }
                    dispatchGroup.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { url, inPlace, error in
                    if let url = url, let savedUrl = copyFile(from: url) {
                        urls.append(savedUrl)
                    } else if let error = error {
                        print("[FileService] Error loading in-place representation: \(error)")
                    }
                    dispatchGroup.leave()
                }
            } else if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url, let savedUrl = copyFile(from: url) {
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
