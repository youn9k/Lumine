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

      // Video Player Layer
      VideoPlayerWrapper(player: viewModel.videoPlayerService.player)
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation {
            isControlsVisible.toggle()
          }
          resetTimer()
        }

      // Controls Overlay
      VStack {
        // Top Bar
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

          HStack(spacing: 16) {
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

            Button {
              NotificationCenter.default.post(name: .togglePiP, object: nil)
            } label: {
              Image(systemName: "pip.enter")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
            }
          }
        }
        .padding(20)

        Spacer()

        // Bottom Control Bar
        VStack(spacing: 20) {
          // Progress Bar
          VStack(spacing: 8) {
            Slider(value: Binding(
              get: { viewModel.videoPlayerService.currentTime },
              set: { viewModel.videoPlayerService.seek(to: $0) }
            ), in: 0 ... viewModel.videoPlayerService.duration)
              .tint(AppColors.mint)
              .onAppear {
                // Custom slider styling if possible, otherwise standard tint
              }

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
                .foregroundStyle(viewModel.videoPlayerService.isLooping ? AppColors.mint : .white.opacity(0.6))
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
                  .foregroundStyle(AppColors.mint)
                  .shadow(color: AppColors.mint.opacity(0.4), radius: 10)
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
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
      }
      .opacity(isControlsVisible ? 1 : 0)
    }
    .buttonStyle(.plain) // Remove default macOS button backgrounds
    //.focusable()
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
