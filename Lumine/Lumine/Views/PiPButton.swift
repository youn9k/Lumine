//import AVKit
//import SwiftUI
//
//struct PiPButton: UIViewRepresentable {
//  let playerLayer: AVPlayerLayer
//
//  func makeUIView(context: Context) -> UIView {
//    let view = UIView()
//
//    // PiP setup requires AVPictureInPictureController which needs a PlayerLayer.
//    // Since we are passing playerLayer, we can try to attach it.
//    // However, AVPictureInPictureController needs to be retained.
//    // And usually it's attached to the AVPlayerViewController or a custom layer.
//
//    // For simplicity in SwiftUI, if we use AVPlayerViewController, it has PiP built-in.
//    // But we hid controls. We can still trigger it programmatically.
//
//    // This is a placeholder for custom PiP button logic.
//    // In a real app, we would manage AVPictureInPictureController in the Coordinator.
//
//    return view
//  }
//
//  func updateUIView(_ uiView: UIView, context: Context) {}
//}
//
///// Helper to toggle PiP
//class PiPManager: NSObject, AVPictureInPictureControllerDelegate {
//  private var pipController: AVPictureInPictureController?
//
//  func setup(with playerLayer: AVPlayerLayer) {
//    if AVPictureInPictureController.isPictureInPictureSupported() {
//      pipController = AVPictureInPictureController(playerLayer: playerLayer)
//      pipController?.delegate = self
//    }
//  }
//
//  func togglePiP() {
//    if pipController?.isPictureInPictureActive == true {
//      pipController?.stopPictureInPicture()
//    } else {
//      pipController?.startPictureInPicture()
//    }
//  }
//}
