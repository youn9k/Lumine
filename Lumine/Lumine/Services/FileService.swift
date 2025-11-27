import Foundation
import UniformTypeIdentifiers

@Observable
final class FileService {
  var files: [URL] = []

  private let supportedVideoTypes: [UTType] = [.movie, .video, .quickTimeMovie, .mpeg4Movie]
  private let bookmarkKey = "FolderBookmarks"

  init() {
    // restoreBookmarks()
  }

  func addSingleFile(url: URL) {
    print("[FileService] 단일 파일 추가: \(url.path)")
    guard url.startAccessingSecurityScopedResource() else {
      print("[FileService] 보안 스코프 리소스 접근 실패: \(url.path)")
      return
    }

    saveBookmark(for: url)

    if !files.contains(url) {
      files.append(url)
    }
  }

  func scanFolder(at url: URL, isRestoring: Bool = false, recursive: Bool = false) {
    print("[FileService] 폴더 스캔 중: \(url.path) (재귀: \(recursive))")

    // 새로운 선택인 경우(복원이 아님), 접근 권한 획득 및 북마크 저장
    if !isRestoring {
      guard url.startAccessingSecurityScopedResource() else {
        print("[FileService] 폴더 접근 실패: \(url.path)")
        return
      }
      saveBookmark(for: url)
    }

    // 디렉토리 내 비디오 파일 열거
    let videoFiles = enumerateVideoFiles(at: url, recursive: recursive)
    print("[FileService] 폴더에서 \(videoFiles.count)개의 비디오 발견")

    // 메인 스레드에서 파일 목록에 추가 (중복 제거)
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

      // 기존 북마크 불러오기
      var bookmarks: [Data] = []
      if let data = UserDefaults.standard.data(forKey: bookmarkKey),
         let existing = try? JSONDecoder().decode([Data].self, from: data) {
        bookmarks = existing
      }

      // 존재하지 않으면 새로 추가
      if !bookmarks.contains(bookmarkData) {
        bookmarks.append(bookmarkData)

        // 저장
        let data = try JSONEncoder().encode(bookmarks)
        UserDefaults.standard.set(data, forKey: bookmarkKey)
        print("[FileService] 북마크 저장 완료: \(url.path)")
      }
    } catch {
      print("[FileService] 북마크 저장 실패: \(error)")
    }
  }

  private func restoreBookmarks() {
    print("[FileService] 북마크 복원 중...")
    guard let data = UserDefaults.standard.data(forKey: bookmarkKey),
          let bookmarks = try? JSONDecoder().decode([Data].self, from: data) else { return }

    for bookmark in bookmarks {
      var isStale = false
      do {
        var options: URL.BookmarkResolutionOptions = []
        #if os(macOS)
          options.insert(.withSecurityScope)
        #endif

        let url = try URL(
          resolvingBookmarkData: bookmark,
          options: options,
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )

        if isStale {
          print("[FileService] 북마크가 오래됨: \(url.path)")
        }

        if url.startAccessingSecurityScopedResource() {
          print("[FileService] 접근 권한 복원: \(url.path)")
          // 디렉토리인지 파일인지 확인
          var isDirectory: ObjCBool = false
          if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
              scanFolder(at: url, isRestoring: true)
            } else {
              // 파일인 경우
              if !files.contains(url) {
                files.append(url)
              }
            }
          }
        } else {
          print("[FileService] 보안 스코프 리소스 접근 실패: \(url.path)")
        }
      } catch {
        print("[FileService] 북마크 해석 오류: \(error)")
      }
    }
  }

  // MARK: - 파일 검증 및 필터링

  /// 주어진 URL이 비디오 파일을 가리키는지 확인
  /// - Parameter url: 확인할 파일 URL
  /// - Returns: 지원되는 비디오 타입이면 true, 그렇지 않으면 false
  private func isVideoFile(at url: URL) -> Bool {
    guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
          let contentType = resourceValues.contentType else {
      return false
    }

    return supportedVideoTypes.contains { contentType.conforms(to: $0) }
  }

  /// 디렉토리 내의 비디오 파일들을 열거
  /// - Parameters:
  ///   - url: 스캔할 디렉토리 URL
  ///   - recursive: 하위 디렉토리도 스캔할지 여부
  /// - Returns: 디렉토리에서 발견된 비디오 파일 URL 배열
  private func enumerateVideoFiles(at url: URL, recursive: Bool) -> [URL] {
    let keys: [URLResourceKey] = [.contentTypeKey, .nameKey]
    var options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]

    if !recursive {
      options.insert(.skipsSubdirectoryDescendants)
    }

    guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: options)
    else {
      print("[FileService] 열거자 생성 실패: \(url.path)")
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

  /// 중복을 피하면서 파일 목록에 파일들을 추가
  /// - Parameter newFiles: 추가할 파일 URL 배열
  private func addUniqueFiles(_ newFiles: [URL]) {
    for file in newFiles {
      if !files.contains(file) {
        files.append(file)
      }
    }
  }

  func loadFiles(from urls: [URL]) {
    print("[FileService] \(urls.count)개 파일 로딩 중...")

    // 비디오 파일 필터링
    let videoFiles = urls.filter { url in
      let isVideo = isVideoFile(at: url)
      if !isVideo {
        print("[FileService] 건너뜀 (비디오 아님): \(url.lastPathComponent)")
      }
      return isVideo
    }

    // 고유 파일 추가 및 개수 계산
    let initialCount = files.count
    addUniqueFiles(videoFiles)
    let addedCount = files.count - initialCount

    print("[FileService] \(addedCount)개 파일 추가됨. 총: \(files.count)")
  }

  func clearFiles() {
    files.removeAll()
    // 참고: 북마크도 지울지 유지할지 결정 필요
    // 현재는 재시작 시 다시 나타나도록 북마크 유지
    // 하지만 사용자는 "Clear"가 완전히 지우는 것을 기대할 수 있음
    // 새 시작을 위해 북마크도 함께 지움
    UserDefaults.standard.removeObject(forKey: bookmarkKey)
    print("[FileService] 모든 파일 및 북마크 삭제됨")
  }

  // MARK: - 파일 처리

  /// 소스 URL의 파일을 Documents 디렉토리로 복사
  /// - Parameter url: 소스 파일 URL
  /// - Returns: 성공 시 대상 URL, 실패 시 nil
  private func copyFileToDocuments(from url: URL) -> URL? {
    guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }

    let destination = documents.appendingPathComponent(url.lastPathComponent)

    do {
      // 보안 스코프인 경우 접근 시작
      let accessing = url.startAccessingSecurityScopedResource()
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }

      if FileManager.default.fileExists(atPath: destination.path) {
        // 기존 파일을 덮어쓰기 위해 복사 후 교체
        let tempDestination = documents.appendingPathComponent(UUID().uuidString)
        try FileManager.default.copyItem(at: url, to: tempDestination)
        try FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempDestination, to: destination)
      } else {
        try FileManager.default.copyItem(at: url, to: destination)
      }

      print("[FileService] 파일 복사 완료: \(destination.lastPathComponent)")
      return destination
    } catch {
      print("[FileService] 파일 복사 오류: \(error)")
      return nil
    }
  }

  /// 단일 NSItemProvider를 처리하여 파일 URL 추출
  /// - Parameter provider: 처리할 아이템 프로바이더
  /// - Returns: 추출 및 복사된 파일 URL, 실패 시 nil
  private func processItemProvider(_ provider: NSItemProvider) async -> URL? {
    // 파일 표현으로 먼저 로드 시도 (드롭에 가장 신뢰할 수 있음)
    if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
      return await withCheckedContinuation { continuation in
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
          if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
            continuation.resume(returning: savedUrl)
          } else {
            if let error = error {
              print("[FileService] 동영상 표현 로드 오류: \(error)")
            }
            continuation.resume(returning: nil)
          }
        }
      }
    } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
      return await withCheckedContinuation { continuation in
        provider
          .loadInPlaceFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] url, _, error in
            if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
              continuation.resume(returning: savedUrl)
            } else {
              if let error = error {
                print("[FileService] 제자리 표현 로드 오류: \(error)")
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
      print("[FileService] 프로바이더가 비디오 타입을 지원하지 않음: \(provider.registeredTypeIdentifiers)")
      return nil
    }
  }

  /// 드롭된 아이템들을 처리하고 추출된 파일 URL들을 반환 (async 버전)
  /// - Parameter providers: 드롭 작업에서 받은 NSItemProvider 배열
  /// - Returns: 성공적으로 추출 및 복사된 파일 URL 배열
  func processDroppedItems(providers: [NSItemProvider]) async -> [URL] {
    print("[FileService] \(providers.count)개 드롭 아이템 처리 중...")

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

      print("[FileService] 아이템 처리 완료. \(urls.count)개의 유효한 비디오 파일 발견")
      return urls
    }
  }

  /// 드롭된 아이템들을 처리하고 추출된 파일 URL들을 반환 (completion handler 버전)
  /// - Parameters:
  ///   - providers: 드롭 작업에서 받은 NSItemProvider 배열
  ///   - completion: 추출된 URL 배열과 함께 호출되는 완료 핸들러
  func processDroppedItems(providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
    print("[FileService] \(providers.count)개 드롭 아이템 처리 중...")
    let dispatchGroup = DispatchGroup()
    var urls: [URL] = []

    for provider in providers {
      dispatchGroup.enter()

      // 파일 표현으로 먼저 로드 시도 (드롭에 가장 신뢰할 수 있음)
      if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
          if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
            urls.append(savedUrl)
          } else if let error = error {
            print("[FileService] 동영상 표현 로드 오류: \(error)")
          }
          dispatchGroup.leave()
        }
      } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
        provider
          .loadInPlaceFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] url, _, error in
            if let url = url, let savedUrl = self?.copyFileToDocuments(from: url) {
              urls.append(savedUrl)
            } else if let error = error {
              print("[FileService] 제자리 표현 로드 오류: \(error)")
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
        print("[FileService] 프로바이더가 비디오 타입을 지원하지 않음: \(provider.registeredTypeIdentifiers)")
        dispatchGroup.leave()
      }
    }

    dispatchGroup.notify(queue: .main) {
      print("[FileService] 아이템 처리 완료. \(urls.count)개의 유효한 비디오 파일 발견")
      completion(urls)
    }
  }
}
