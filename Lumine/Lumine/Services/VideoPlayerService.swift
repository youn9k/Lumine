import AVKit
import Foundation
import Observation

@Observable
final class VideoPlayerService {
  var player: AVPlayer = AVPlayer()
  var isPlaying: Bool = false
  var currentTime: TimeInterval = 0
  var duration: TimeInterval = 0
  var rate: Float = 1.0
  var isLooping: Bool = false

  private var timeObserver: Any?

  init() {
    setupObservers()
  }

  deinit {
    if let timeObserver = timeObserver {
      player.removeTimeObserver(timeObserver)
    }
  }

  func load(url: URL) {
    let item = AVPlayerItem(url: url)
    player.replaceCurrentItem(with: item)

    // Reset state
    isPlaying = false
    currentTime = 0
    duration = 0

    // Wait for duration to be available
    Task {
      if let duration = try? await item.asset.load(.duration) {
        await MainActor.run {
          self.duration = CMTimeGetSeconds(duration)
        }
      }
    }

    play()
  }

  func play() {
    player.play()
    isPlaying = true
    player.rate = rate // Restore rate
    print("[VideoPlayer] Playing (Rate: \(rate))")
  }

  func pause() {
    player.pause()
    isPlaying = false
    print("[VideoPlayer] Paused")
  }

  func togglePlayPause() {
    if isPlaying {
      pause()
    } else {
      play()
    }
  }

  func seek(to time: TimeInterval) {
    let cmTime = CMTime(seconds: time, preferredTimescale: 600)
    player.seek(to: cmTime)
  }

  func seek(by seconds: TimeInterval) {
    let newTime = currentTime + seconds
    seek(to: max(0, min(newTime, duration)))
  }

  func setRate(_ newRate: Float) {
    rate = newRate
    if isPlaying {
      player.rate = newRate
    }
  }

  private func setupObservers() {
    // Observe time
    let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      self?.currentTime = CMTimeGetSeconds(time)
    }

    // Observe status if needed (e.g. ready to play)
    
    // Observe end of playback
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] notification in
      guard let self = self,
            let item = notification.object as? AVPlayerItem,
            item == self.player.currentItem else { return }
      
      if self.isLooping {
        self.player.seek(to: .zero)
        self.player.play()
      } else {
        self.isPlaying = false
        print("[VideoPlayer] Playback finished")
      }
    }
  }
}
