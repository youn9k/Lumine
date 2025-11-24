import SwiftUI

struct MainView: View {
  @State private var viewModel = MainViewModel()
  @State private var sidebarState: SidebarState = .expanded
  /// User requested configurable sidebar position (Left/Right)
  @State private var sidebarPosition: HorizontalAlignment = .leading

  var body: some View {
    ZStack(alignment: Alignment(horizontal: sidebarPosition, vertical: .center)) {
      // Background
      AppColors.backgroundGradient
        .ignoresSafeArea()

      // Main Content Layer
      PlayerContainerView(viewModel: viewModel, sidebarState: sidebarState)
        .padding(
          .leading,
          !viewModel.isFullScreen && sidebarPosition == .leading && sidebarState.isVisible
            ? sidebarState.width + LayoutConstants.sidebarPadding + LayoutConstants.cardPadding
            : (viewModel.isFullScreen ? 0 : LayoutConstants.cardPadding)
        )
        .padding(
          .trailing,
          !viewModel.isFullScreen && sidebarPosition == .trailing && sidebarState.isVisible
            ? sidebarState.width + LayoutConstants.sidebarPadding + LayoutConstants.cardPadding
            : (viewModel.isFullScreen ? 0 : LayoutConstants.cardPadding)
        )
        .padding(.vertical, viewModel.isFullScreen ? 0 : LayoutConstants.cardPadding)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sidebarState)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sidebarPosition)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isFullScreen)
        .ignoresSafeArea(edges: viewModel.isFullScreen ? .all : [])

      // Sidebar
      if !viewModel.isFullScreen {
        SidebarView(viewModel: viewModel, sidebarState: $sidebarState, position: $sidebarPosition)
      }
    }
    .onAppear {
      viewModel.send(.lifeCycle(.onAppear))
    }
  }
}
