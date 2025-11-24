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
            content(url: url)
              .frame(width: proxy.size.width, height: proxy.size.height)
              .clipped()
              .onAppear {
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
      .onTapGesture {
        viewModel.send(.viewAction(.playPause))
      }
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
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder func content(url: URL) -> some View {
    ZStack {
      Color.black

      videoPlayerView(url: url)

      overlayView(url: url)
    }
  }

  @ViewBuilder
  private func videoPlayerView(url: URL) -> some View {
    if viewModel.fileService.files.firstIndex(of: url) == viewModel.currentVideoIndex {
      VideoPlayerWrapper(player: viewModel.videoPlayerService.player, videoGravity: .resizeAspect)
        .id(url)
    } else {
      ThumbnailView(url: url)
    }
  }

  @ViewBuilder
  private func overlayView(url: URL) -> some View {
    VStack {
      topControls
        .padding(20)
        .padding(.horizontal)

      Spacer()

      bottomInfo(url: url)
    }
  }

  private var topControls: some View {
    HStack {
      Button {
        viewModel.send(.viewAction(.closePlayer))
      } label: {
        circleButtonImage(systemName: "xmark", size: 18)
      }

      Spacer()

      Button {
        viewModel.send(.viewAction(.togglePlayerMode))
      } label: {
        circleButtonImage(systemName: "inset.filled.rectangle", size: 16)
      }

      Button {
        viewModel.send(.viewAction(.toggleFullScreen))
      } label: {
        circleButtonImage(
          systemName: viewModel
            .isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
          size: 16
        )
      }
    }
  }

  private func bottomInfo(url: URL) -> some View {
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

  private func circleButtonImage(systemName: String, size: CGFloat) -> some View {
    Image(systemName: systemName)
      .font(.system(size: size, weight: .semibold))
      .foregroundStyle(.white)
      .padding(12)
      .background(.ultraThinMaterial)
      .clipShape(Circle())
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
