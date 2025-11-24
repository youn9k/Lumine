import Foundation
import Observation

@Observable
final class MainViewModel {
  // MARK: - Services
  let videoPlayerService = VideoPlayerService()
  let fileService = FileService()

  // MARK: - State
  private(set) var selectedCategory: SidebarCategory = .allVideos
  private(set) var seekInterval: TimeInterval = 5.0
  private(set) var isShowPlayer: Bool = false
  private(set) var playerMode: PlayerMode = .normal
  private(set) var currentVideoIndex: Int = 0

  enum PlayerMode {
    case normal
    case shortForm
  }

  // MARK: - Action Handling
  func send(_ action: Action) {
    switch action {
    case let .lifeCycle(action):
      handle(action)
    case let .viewAction(action):
      handle(action)
    }
  }

  private func handle(_ action: Lifecycle) {
    print("[Action] Lifecycle: \(action)")
    switch action {
    case .onAppear:
      // Initial setup
      break
    }
  }

  private func handle(_ action: ViewAction) {
    print("[Action] ViewAction: \(action)")
    switch action {
    case let .didSelectCategory(category):
      selectedCategory = category
      print("[State] Selected Category: \(category.rawValue)")

    case let .didDropFiles(urls):
      print("[Action] Processing dropped files: \(urls.count) files")
      fileService.loadFiles(from: urls)

    case let .didChangeSeekInterval(interval):
      seekInterval = interval
      print("[State] Seek Interval changed to: \(interval)")

    case let .didSelectVideo(url):
      print("[Action] Selected video: \(url.lastPathComponent)")
      if let index = fileService.files.firstIndex(of: url) {
        currentVideoIndex = index
      }
      videoPlayerService.load(url: url)
      isShowPlayer = true

    case .closePlayer:
      isShowPlayer = false
      videoPlayerService.pause()
      print("[State] Player closed")

    case .togglePlayerMode:
      playerMode = playerMode == .normal ? .shortForm : .normal
      // Auto-loop for short form, restore or default for normal
      videoPlayerService.isLooping = (playerMode == .shortForm)
      print("[State] Player mode toggled to: \(playerMode) (Looping: \(videoPlayerService.isLooping))")

    case .playPause:
      videoPlayerService.togglePlayPause()

    case .seekForward:
      videoPlayerService.seek(by: seekInterval)

    case .seekBackward:
      videoPlayerService.seek(by: -seekInterval)

    case .playNext:
      playNextVideo()

    case .playPrevious:
      playPreviousVideo()

    case let .didImportFolder(result, recursive):
      switch result {
      case let .success(url):
        print("[Action] Folder imported: \(url.path) (Recursive: \(recursive))")
        fileService.scanFolder(at: url, recursive: recursive)

      case let .failure(error):
        print("[Action] Folder import failed: \(error)")
      }

    case .toggleLooping:
      videoPlayerService.isLooping.toggle()
      print("[State] Looping toggled to: \(videoPlayerService.isLooping)")
    }
  }

  private func playNextVideo() {
    guard !fileService.files.isEmpty else { return }
    let nextIndex = (currentVideoIndex + 1) % fileService.files.count
    currentVideoIndex = nextIndex
    videoPlayerService.load(url: fileService.files[nextIndex])
  }

  private func playPreviousVideo() {
    guard !fileService.files.isEmpty else { return }
    let prevIndex = (currentVideoIndex - 1 + fileService.files.count) % fileService.files.count
    currentVideoIndex = prevIndex
    videoPlayerService.load(url: fileService.files[prevIndex])
  }
}
