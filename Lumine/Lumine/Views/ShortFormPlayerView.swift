import AVKit
import SwiftUI

struct ShortFormPlayerView: View {
  @Bindable var viewModel: MainViewModel
  @StateObject private var shortcuts = KeyboardShortcuts.shared

  var body: some View {
    GeometryReader { proxy in
      ScrollView(.vertical) {
        LazyVStack(spacing: 0) {
          ForEach(viewModel.fileService.files, id: \.self) { url in
            ZStack {
              Color.black
              
              // Video Player (Only play if current)
              if viewModel.fileService.files.firstIndex(of: url) == viewModel.currentVideoIndex {
                VideoPlayerWrapper(player: viewModel.videoPlayerService.player, videoGravity: .resizeAspect)
                  .id(url) // Force recreate if needed, or keep
              } else {
                // Thumbnail or Placeholder
                ThumbnailView(url: url)
              }

              // Overlay Info
              VStack {
                HStack {
                  Button {
                    viewModel.send(.viewAction(.closePlayer))
                  } label: {
                    Image(systemName: "xmark")
                      .font(.system(size: 18, weight: .semibold))
                      .foregroundStyle(.white)
                      .padding(12)
                      .background(.ultraThinMaterial)
                      .clipShape(Circle())
                  }
                  Spacer()
                  Button {
                    viewModel.send(.viewAction(.togglePlayerMode))
                  } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundStyle(.white)
                      .padding(12)
                      .background(.ultraThinMaterial)
                      .clipShape(Circle())
                  }
                }
                .padding(20)
                .padding(.horizontal)

                Spacer()

                VStack(alignment: .leading) {
                  Text(url.lastPathComponent)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                  LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
              }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .onAppear {
              // If we scroll to this view, play it
              // But ScrollView onAppear triggers early.
              // Better to use scrollPosition or geometry detection.
              // For simplicity in this MVP, we rely on manual swipe logic or paging.

              // Ensure loop is enabled for short form
              if viewModel.playerMode == .shortForm {
                viewModel.videoPlayerService.isLooping = true
              }
            }
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: Binding(
        get: { viewModel.fileService.files[safe: viewModel.currentVideoIndex] },
        set: { url in
          if let url {
            viewModel.send(.viewAction(.didSelectVideo(url)))
          }
        }
      ))
      .ignoresSafeArea()
    }
    .onTapGesture {
      viewModel.send(.viewAction(.playPause))
    }
    //.focusable()
    #if os(macOS)
      .onReceive(shortcuts.keySubject) { key in
        switch key {
        case .upArrow:
          viewModel.send(.viewAction(.playPrevious))
        case .downArrow:
          viewModel.send(.viewAction(.playNext))
        case .space:
          viewModel.send(.viewAction(.playPause))
        default:
          break
        }
      }
    #endif
    .buttonStyle(.plain) // Remove default macOS button backgrounds
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
