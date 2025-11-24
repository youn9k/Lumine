import SwiftUI

@main
struct LumineApp: App {
    init() {
        AudioSessionService.shared.configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowToolbarLabelStyle(fixed: .automatic)
    }
}
