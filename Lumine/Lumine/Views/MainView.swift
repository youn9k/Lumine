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
          sidebarPosition == .leading && sidebarState.isVisible
            ? sidebarState.width + LayoutConstants.sidebarPadding + LayoutConstants.cardPadding
            : LayoutConstants.cardPadding
        )
        .padding(
          .trailing,
          sidebarPosition == .trailing && sidebarState.isVisible
            ? sidebarState.width + LayoutConstants.sidebarPadding + LayoutConstants.cardPadding
            : LayoutConstants.cardPadding
        )
        .padding(.vertical, LayoutConstants.cardPadding)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sidebarState)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sidebarPosition)

      // Floating Sidebar
      SidebarView(viewModel: viewModel, sidebarState: $sidebarState, position: $sidebarPosition)
    }
    .onAppear {
      viewModel.send(.lifeCycle(.onAppear))
    }
  }
}
