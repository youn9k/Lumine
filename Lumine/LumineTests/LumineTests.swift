import Testing
import Foundation
@testable import Lumine

struct LumineTests {

    @Test("Thumbnail Generation Error Handling")
    func testThumbnailGenerationError() async {
        let service = ThumbnailService.shared
        let invalidUrl = URL(fileURLWithPath: "/invalid/path/video.mp4")
        
        // Expectation: generateThumbnail should throw an error for invalid file
        await #expect(throws: Error.self) {
            _ = try await service.generateThumbnail(for: invalidUrl)
        }
    }

    @Test("Loop Toggle in Normal Mode")
    func testLoopToggleInNormalMode() async {
        let viewModel = MainViewModel()
        
        // Initial state
        #expect(viewModel.playerMode == .normal)
        #expect(!viewModel.videoPlayerService.isLooping)
        
        // Toggle loop
        viewModel.send(.viewAction(.toggleLooping))
        #expect(viewModel.videoPlayerService.isLooping)
        
        // Toggle again
        viewModel.send(.viewAction(.toggleLooping))
        #expect(!viewModel.videoPlayerService.isLooping)
    }

    @Test("Auto Loop in ShortForm Mode")
    func testAutoLoopInShortFormMode() async {
        let viewModel = MainViewModel()
        
        // Switch to ShortForm
        viewModel.send(.viewAction(.togglePlayerMode))
        #expect(viewModel.playerMode == .shortForm)
        #expect(viewModel.videoPlayerService.isLooping)
        
        // Switch back to Normal
        viewModel.send(.viewAction(.togglePlayerMode))
        #expect(viewModel.playerMode == .normal)
        #expect(!viewModel.videoPlayerService.isLooping)
    }
    
    @Test("MainViewModel Play/Pause State")
    func testPlayPauseState() async {
        let viewModel = MainViewModel()
        
        // Initial state
        #expect(!viewModel.videoPlayerService.isPlaying)
        
        // Play
        viewModel.send(.viewAction(.playPause))
        #expect(viewModel.videoPlayerService.isPlaying)
        
        // Pause
        viewModel.send(.viewAction(.playPause))
        #expect(!viewModel.videoPlayerService.isPlaying)
    }
}
