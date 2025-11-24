import SwiftUI

struct PlayerContainerView: View {
  var viewModel: MainViewModel
  var sidebarState: SidebarState
  @Namespace private var animation
  @State private var dragOffset: CGSize = .zero
  @State private var currentScale: CGFloat = 1.0

  var body: some View {
    ZStack {
      if viewModel.isShowPlayer {
        ZStack {
          switch viewModel.playerMode {
          case .normal:
            NormalPlayerView(viewModel: viewModel)
              .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
          case .shortForm:
            ShortFormPlayerView(viewModel: viewModel)
              .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
          }
        }
        // Drag to close logic - keeping it but adjusting for card layout
        .scaleEffect(currentScale)
        .offset(y: dragOffset.height)
        .gesture(
          DragGesture()
            .onChanged { value in
              // MARK: Drag Down
              if value.translation.height > 0 {
                dragOffset = value.translation
              }
              // MARK: Drag Up: 이동 + 확대
              else if viewModel.playerMode == .normal && value.translation.height < 0 {
                // 드래그를 많이 할 수록 적게 늘어남
                let dragAmount = -value.translation.height
                let resistance = 33.0 * log10(dragAmount / 33.0 + 1)
                dragOffset = CGSize(width: 0, height: -resistance)
                
                // 최대 1.05배
                let scale = min(1.0 + (dragAmount / 1000.0), 1.05)
                currentScale = scale
              }
            }
            .onEnded { value in
              // MARK: Drag down to close
              if value.translation.height > 100 {
                // 풀스크린이라면 풀스크린 해제
                if viewModel.isFullScreen {
                  withAnimation(.spring) {
                    viewModel.send(.viewAction(.setFullScreen(false)))
                    dragOffset = .zero
                    currentScale = 1.0
                  }
                } else {
                  withAnimation(.spring) {
                    viewModel.send(.viewAction(.closePlayer))
                    dragOffset = .zero
                    currentScale = 1.0
                  }
                }
              } 
              // MARK: Drag up to full screen
              else if viewModel.playerMode == .normal && value.translation.height < -100 {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                  viewModel.send(.viewAction(.setFullScreen(true)))
                  dragOffset = .zero
                  currentScale = 1.0
                }
              }
              else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                  dragOffset = .zero
                  currentScale = 1.0
                }
              }
            }
        )
      } else {
        // When no player is shown, we might show a placeholder or the library if it was intended to be here.
        // Given the sidebar has library navigation, this area could be a "Home" or "Empty" state.
        // For now, let's keep LibraryView but styled within the card.
        LibraryView(viewModel: viewModel, animation: animation)
          .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
      }
    }
  }
}

#Preview {
  ZStack {
    Rectangle()
      .fill(Color.lavender)
    PlayerContainerView(viewModel: MainViewModel(), sidebarState: .expanded)
      .padding(40)
  }
}
