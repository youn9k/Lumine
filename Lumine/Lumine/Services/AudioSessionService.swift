import AVFoundation
import Foundation

final class AudioSessionService {
    static let shared = AudioSessionService()
    
    private init() {}
    
    func configureAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
            print("[AudioSessionService] Audio session configured: Category .playback, Mode .moviePlayback")
        } catch {
            print("[AudioSessionService] Failed to configure audio session: \(error)")
        }
        #else
        print("[AudioSessionService] Audio session configuration skipped (not iOS)")
        #endif
    }
}
