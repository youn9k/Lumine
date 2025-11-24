import Foundation

extension MainViewModel {
  enum Action {
    case lifeCycle(Lifecycle)
    case viewAction(ViewAction)
  }

  enum Lifecycle {
    case onAppear
  }

  enum ViewAction {
    case didSelectCategory(SidebarCategory)
    case didDropFiles([URL])
    case didChangeSeekInterval(TimeInterval)
    case didSelectVideo(URL)
    case didImportFolder(Result<URL, Error>, recursive: Bool)
    case closePlayer
    case togglePlayerMode
    case playPause
    case seekForward
    case seekBackward
    case playNext
    case playPrevious
    case toggleLooping
  }
}
