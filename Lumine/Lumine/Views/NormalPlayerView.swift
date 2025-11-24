import AVKit
import SwiftUI

struct NormalPlayerView: View {
  @Bindable var viewModel: MainViewModel
  @State private var isControlsVisible: Bool = true
  @State private var hideTimer: Timer?
  @StateObject private var shortcuts = KeyboardShortcuts.shared

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      videoPlayerView

      controlsOverlay
    }
    .buttonStyle(.plain)
    .onAppear {
      resetTimer()
    }
    .onDisappear {
      hideTimer?.invalidate()
    }
    #if os(macOS)
    .onReceive(shortcuts.keySubject) { key in
      switch key {
      case .space:
        viewModel.send(.viewAction(.playPause))
        resetTimer()
      case .leftArrow:
        viewModel.send(.viewAction(.seekBackward))
        resetTimer()
      case .rightArrow:
        viewModel.send(.viewAction(.seekForward))
        resetTimer()
      case .escape:
        viewModel.send(.viewAction(.closePlayer))
        resetTimer()
      default:
        break
      }
    }
    #endif
  }

  private var videoPlayerView: some View {
    VideoPlayerWrapper(player: viewModel.videoPlayerService.player)
      .ignoresSafeArea()
      .onTapGesture {
        withAnimation {
          isControlsVisible.toggle()
        }
        resetTimer()
      }
  }

  private var controlsOverlay: some View {
    VStack {
      topControls
        .padding(20)

      Spacer()

      bottomControls
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    .opacity(isControlsVisible ? 1 : 0)
  }

  private var topControls: some View {
    HStack {
      Button {
        viewModel.send(.viewAction(.closePlayer))
      } label: {
        circleButtonImage(systemName: "xmark", size: 18)
      }

      Spacer()

      HStack(spacing: 16) {
        Button {
          viewModel.send(.viewAction(.togglePlayerMode))
        } label: {
          circleButtonImage(systemName: "rectangle.stack.fill", size: 16)
        }

        Button {
          viewModel.send(.viewAction(.toggleFullScreen))
        } label: {
          circleButtonImage(
            systemName: viewModel.isFullScreen
              ? "arrow.down.right.and.arrow.up.left"
              : "arrow.up.left.and.arrow.down.right",
            size: 16
          )
        }

        Button {
          NotificationCenter.default.post(name: .togglePiP, object: nil)
        } label: {
          circleButtonImage(systemName: "pip.enter", size: 16)
        }
      }
    }
  }

  private var bottomControls: some View {
    VStack(spacing: 20) {
      // Progress Bar
      VStack(spacing: 8) {
        Slider(value: Binding(
          get: { viewModel.videoPlayerService.currentTime },
          set: { viewModel.videoPlayerService.seek(to: $0) }
        ), in: 0 ... viewModel.videoPlayerService.duration)
          .tint(.white.opacity(0.4))

        HStack {
          Text(formatTime(viewModel.videoPlayerService.currentTime))
          Spacer()
          Text(formatTime(viewModel.videoPlayerService.duration))
        }
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.8))
        .monospacedDigit()
      }

      // Playback Controls
      HStack(spacing: 40) {
        Button {
          viewModel.send(.viewAction(.toggleLooping))
          resetTimer()
        } label: {
          Image(systemName: "repeat")
            .font(.title3)
            .foregroundStyle(
              viewModel.videoPlayerService.isLooping
                ? AppColors.skyBlue
                : .white.opacity(0.6)
            )
        }

        Spacer()

        HStack(spacing: 32) {
          Button {
            viewModel.send(.viewAction(.seekBackward))
            resetTimer()
          } label: {
            Image(systemName: "gobackward.5")
              .font(.title2)
              .foregroundStyle(.white)
          }

          Button {
            viewModel.send(.viewAction(.playPause))
            resetTimer()
          } label: {
            Image(systemName: viewModel.videoPlayerService.isPlaying ? "pause.fill" : "play.fill")
              .font(.system(size: 44))
              .foregroundStyle(AppColors.skyBlue)
              .shadow(color: AppColors.skyBlue.opacity(0.4), radius: 10)
          }

          Button {
            viewModel.send(.viewAction(.seekForward))
            resetTimer()
          } label: {
            Image(systemName: "goforward.5")
              .font(.title2)
              .foregroundStyle(.white)
          }
        }

        Spacer()

        // Placeholder for balance
        Color.clear.frame(width: 24, height: 24)
      }
    }
  }

  private func circleButtonImage(systemName: String, size: CGFloat) -> some View {
    Image(systemName: systemName)
      .font(.system(size: size, weight: .semibold))
      .foregroundStyle(.white)
      .padding(12)
      .background(.ultraThinMaterial)
      .clipShape(Circle())
  }

  private func resetTimer() {
    hideTimer?.invalidate()
    isControlsVisible = true
    hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
      withAnimation {
        isControlsVisible = false
      }
    }
  }

  private func formatTime(_ time: Double) -> String {
    let seconds = Int(time)
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
  }
}
