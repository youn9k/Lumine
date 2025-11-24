import SwiftUI

@main
struct LumineApp: App {
    init() {
        AudioSessionService.shared.configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup(id: "MainWindow") {
            MainView()
        }
        .windowToolbarLabelStyle(fixed: .automatic)
        #if os(macOS)
        .defaultSize(calculateDefaultWindowSize())
        #endif
    }
    
    #if os(macOS)
    private func calculateDefaultWindowSize() -> CGSize {
        if let screen = NSScreen.main {
            let width = screen.visibleFrame.width * (2.0 / 3.0)
            let height = width * (9.0 / 16.0)
            return CGSize(width: width, height: height)
        }
        return CGSize(width: 1200, height: 675) // Fallback 16:9
    }
    #endif
}
