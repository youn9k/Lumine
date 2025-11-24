import SwiftUI

enum SidebarState {
  case hidden
  case compact
  case expanded

  var width: CGFloat {
    switch self {
    case .hidden: return 0
    case .compact: return LayoutConstants.sidebarCompactWidth
    case .expanded: return LayoutConstants.sidebarExpandedWidth
    }
  }

  var isVisible: Bool {
    self != .hidden
  }
}

struct FloatingSidebarView: View {
  @Bindable var viewModel: MainViewModel
  @Binding var sidebarState: SidebarState
  var position: HorizontalAlignment = .leading
  @State private var isImporting: Bool = false
  @State private var pendingImportUrl: URL?
  @State private var isShowRecursiveAlert = false

  var body: some View {
    ZStack(alignment: position == .leading ? .leading : .trailing) {
      // Sidebar Content
      if sidebarState.isVisible {
        VStack(alignment: .leading, spacing: 20) {
          headerView

          if sidebarState == .expanded {
            contentView
              .transition(.opacity.combined(with: .move(edge: position == .leading ? .leading : .trailing)))
          } else {
            compactContentView
              .transition(.opacity)
          }

          Spacer()
        }
        .frame(width: sidebarState.width)
        // Background removed for Arc-like "text on canvas" look
        .padding(.vertical, LayoutConstants.sidebarPadding)
        .padding(.leading, position == .leading ? LayoutConstants.sidebarPadding : 0)
        .padding(.trailing, position == .trailing ? LayoutConstants.sidebarPadding : 0)
      }

      // Toggle Button (Always visible or managed externally?
      // Requirement says "Sidebar with three states: Hidden... Toggle button to cycle or show/hide"
      // We'll place a toggle button that is always accessible or part of the sidebar when visible.
      // If hidden, we need a way to bring it back. Usually a button on the main content or a gesture.
      // For now, let's assume the toggle is part of the sidebar when visible,
      // and we might need an external trigger if hidden.
      // Actually, let's keep the toggle button inside the sidebar area but make sure it handles the transitions.)
    }
    .buttonStyle(.plain) // Remove default macOS button backgrounds
    // Animation is handled by the parent or state changes
  }

  var headerView: some View {
    HStack {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
          cycleState()
        }
      } label: {
        Image(systemName: "sidebar.left")
          .font(.title2)
          .foregroundStyle(.primary)
          .padding(8)
      }

      if sidebarState == .expanded {
        Text("Lumine")
          .font(.headline)
          .transition(.opacity.combined(with: .move(edge: .leading)))

        Spacer()
      }
    }
    .padding(.horizontal, sidebarState == .expanded ? 16 : 0)
    .frame(maxWidth: .infinity, alignment: sidebarState == .expanded ? .leading : .center)
    .padding(.top, 16)
  }

  var compactContentView: some View {
    VStack(spacing: 24) {
      Divider()
        .padding(.horizontal)

      ForEach(SidebarCategory.allCases) { category in
        Button {
          viewModel.send(.viewAction(.didSelectCategory(category)))
        } label: {
          Image(systemName: category.iconName)
            .font(.system(size: 20))
            .foregroundStyle(.secondary)
            .frame(width: 40, height: 40)
            .background(
              viewModel.selectedCategory == category ? Color.secondary.opacity(0.05) : Color.clear
            )
            .clipShape(Circle())
        }
      }

      Divider()
        .padding(.horizontal)

      Button {
        isImporting = true
      } label: {
        Image(systemName: "folder.badge.plus")
          .font(.system(size: 20))
          .foregroundStyle(.secondary)
          .frame(width: 40, height: 40)
      }
    }
    .padding(.top, 10)
  }

  var contentView: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        // Library Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Library")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

          ForEach(SidebarCategory.allCases) { category in
            Button {
              viewModel.send(.viewAction(.didSelectCategory(category)))
            } label: {
              HStack {
                Image(systemName: category.iconName)
                  .frame(width: 24)
                Text(category.rawValue)
                Spacer()
              }
              .padding(.vertical, 10)
              .padding(.horizontal)
              .background(
                viewModel.selectedCategory == category ? Color.secondary.opacity(0.05) : Color.clear
              )
              .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .foregroundStyle(.primary)
          }

          Text("import Content")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
          
          // Add Folder Button
          Button {
            isImporting = true
          } label: {
            HStack {
              Image(systemName: "folder.badge.plus")
                .frame(width: 24)
              Text("Add Folder")
              Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .foregroundStyle(.primary)
          .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
          ) { result in
            switch result {
            case let .success(urls):
              if let url = urls.first {
                pendingImportUrl = url
                isShowRecursiveAlert = true
              }
            case let .failure(error):
              viewModel.send(.viewAction(.didImportFolder(.failure(error), recursive: false)))
            }
          }
          .alert("가져오기 방식", isPresented: $isShowRecursiveAlert) {
            Button("현재 폴더에서 가져오기") {
              if let url = pendingImportUrl {
                viewModel.send(.viewAction(.didImportFolder(.success(url), recursive: false)))
              }
            }
            Button("하위 폴더 포함해서 가져오기") {
              if let url = pendingImportUrl {
                viewModel.send(.viewAction(.didImportFolder(.success(url), recursive: true)))
              }
            }
            Button("Cancel", role: .cancel) {}
          } message: {
            Text("하위 폴더가 많을 경우 시간이 오래 걸릴 수 있습니다.")
          }
        }

        // Settings Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Settings")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

          HStack {
            Image(systemName: "goforward.plus")
              .frame(width: 24)
            Text("Seek Interval")
            Spacer()
            Picker("", selection: Binding(
              get: { viewModel.seekInterval },
              set: { viewModel.send(.viewAction(.didChangeSeekInterval($0))) }
            )) {
              Text("5s").tag(5.0)
              Text("10s").tag(10.0)
              Text("15s").tag(15.0)
              Text("30s").tag(30.0)
              Text("60s").tag(60.0)
            }
            .labelsHidden()
            .tint(.secondary)
          }
          .padding(.vertical, 8)
          .padding(.horizontal)
        }
      }
      .padding(.vertical)
    }
  }

  private func cycleState() {
    switch sidebarState {
    case .expanded:
      sidebarState = .compact
    case .compact:
      sidebarState = .expanded
//      sidebarState = .hidden
    case .hidden:
      sidebarState = .expanded
    }
  }
}

#Preview {
  @Previewable @State var sidebarState: SidebarState = .compact
  FloatingSidebarView(
    viewModel: MainViewModel(),
    sidebarState: $sidebarState,
    position: .trailing
  )
}
