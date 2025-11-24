import AVKit
import SwiftUI

#if os(iOS)
  import UIKit

  struct VideoPlayerWrapper: UIViewRepresentable {
    let player: AVPlayer
    var videoGravity: AVLayerVideoGravity = .resizeAspect

    func makeUIView(context: Context) -> PlayerUIView {
      let view = PlayerUIView(player: player)
      view.playerLayer.videoGravity = videoGravity
      return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
      uiView.playerLayer.player = player
      uiView.playerLayer.videoGravity = videoGravity
    }
  }

  class PlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()
    var pipController: AVPictureInPictureController?

    init(player: AVPlayer) {
      super.init(frame: .zero)
      playerLayer.player = player
      // Default gravity, will be updated by wrapper
      playerLayer.videoGravity = .resizeAspect
      
      layer.addSublayer(playerLayer)
      
      // Enable PiP if supported
      if AVPictureInPictureController.isPictureInPictureSupported() {
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
      }

      NotificationCenter.default.addObserver(self, selector: #selector(togglePiP), name: .togglePiP, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      playerLayer.frame = bounds
    }

    @objc func togglePiP() {
      if pipController?.isPictureInPictureActive == true {
        pipController?.stopPictureInPicture()
      } else {
        pipController?.startPictureInPicture()
      }
    }
  }

#else
  import AppKit

  struct VideoPlayerWrapper: NSViewRepresentable {
    let player: AVPlayer
    var videoGravity: AVLayerVideoGravity = .resizeAspect

    func makeNSView(context: Context) -> PlayerNSView {
      let view = PlayerNSView(player: player)
      view.playerLayer.videoGravity = videoGravity
      return view
    }

    func updateNSView(_ nsView: PlayerNSView, context: Context) {
      nsView.playerLayer.player = player
      nsView.playerLayer.videoGravity = videoGravity
    }
  }

  class PlayerNSView: NSView {
    let playerLayer = AVPlayerLayer()
    var pipController: AVPictureInPictureController?

    init(player: AVPlayer) {
      super.init(frame: .zero)
      playerLayer.player = player
      playerLayer.videoGravity = .resizeAspect
      wantsLayer = true
      layer?.addSublayer(playerLayer)

      // Enable PiP if supported
      if AVPictureInPictureController.isPictureInPictureSupported() {
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
      }

      NotificationCenter.default.addObserver(self, selector: #selector(togglePiP), name: .togglePiP, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
      super.layout()
      playerLayer.frame = bounds
    }

    @objc func togglePiP() {
      if pipController?.isPictureInPictureActive == true {
        pipController?.stopPictureInPicture()
      } else {
        pipController?.startPictureInPicture()
      }
    }
  }
#endif
