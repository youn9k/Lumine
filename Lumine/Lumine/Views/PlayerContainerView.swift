import SwiftUI

struct PlayerContainerView: View {
  var viewModel: MainViewModel
  var sidebarState: SidebarState
  @Namespace private var animation
  @State private var dragOffset: CGSize = .zero

  var body: some View {
    ZStack {
      // Card Background
//      RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
//        .fill(.ultraThinMaterial)
//        .shadow(
//          color: .black.opacity(0.1),
//          radius: LayoutConstants.cardShadowRadius,
//          x: 0,
//          y: LayoutConstants.cardShadowY
//        )

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
        .matchedGeometryEffect(
          id: viewModel.fileService.files[safe: viewModel.currentVideoIndex] ?? URL(fileURLWithPath: ""),
          in: animation
        )
        // Drag to close logic - keeping it but adjusting for card layout
        .offset(y: dragOffset.height)
        .gesture(
          DragGesture()
            .onChanged { value in
              if value.translation.height > 0 {
                dragOffset = value.translation
              }
            }
            .onEnded { value in
              if value.translation.height > 100 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                  viewModel.send(.viewAction(.closePlayer))
                  dragOffset = .zero
                }
              } else {
                withAnimation {
                  dragOffset = .zero
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
