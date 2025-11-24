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

struct SidebarView: View {
  @Bindable var viewModel: MainViewModel
  @Binding var sidebarState: SidebarState
  @Binding var position: HorizontalAlignment
  @State private var isImporting: Bool = false
  @State private var isImportingFile: Bool = false
  @State private var pendingImportUrl: URL?
  @State private var isShowRecursiveAlert = false

  var body: some View {
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
      .buttonStyle(.plain)
      .frame(width: sidebarState.width)
      // Background removed for Arc-like "text on canvas" look
      .padding(.vertical, LayoutConstants.sidebarPadding)
      .padding(.leading, position == .leading ? LayoutConstants.sidebarPadding : 0)
      .padding(.trailing, position == .trailing ? LayoutConstants.sidebarPadding : 0)
    } else {
      // Ensure we return something if hidden, though isVisible check above handles it.
      // If hidden, width is 0, so it effectively disappears.
      // However, if we want to keep the toggle button accessible even when hidden (if logic changes),
      // we might need a different approach.
      // For now, based on current logic:
      EmptyView()
    }
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
          Text("라이브러리")
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

          Text("불러오기")
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
              Text("폴더로 가져오기")
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
            Button("현재 폴더만(권장)") {
              if let url = pendingImportUrl {
                viewModel.send(.viewAction(.didImportFolder(.success(url), recursive: false)))
              }
            }
            Button("하위 폴더 포함") {
              if let url = pendingImportUrl {
                viewModel.send(.viewAction(.didImportFolder(.success(url), recursive: true)))
              }
            }
            Button("Cancel", role: .cancel) {}
          } message: {
            Text("하위 폴더가 많을 경우 시간이 오래 걸릴 수 있습니다.")
          }
          
          // Add File Button
          Button {
            isImportingFile = true
          } label: {
            HStack {
              Image(systemName: "doc.badge.plus")
                .frame(width: 24)
              Text("바로 재생")
              Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .foregroundStyle(.primary)
          .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: [.movie, .video],
            allowsMultipleSelection: false
          ) { result in
            switch result {
            case let .success(urls):
              if let url = urls.first {
                viewModel.send(.viewAction(.didImportSingleVideo(.success(url))))
              }
            case let .failure(error):
              viewModel.send(.viewAction(.didImportSingleVideo(.failure(error))))
            }
          }
        }

        // Settings Section
        VStack(alignment: .leading, spacing: 12) {
          Text("설정")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

          HStack {
            Image(systemName: "goforward.plus")
              .frame(width: 24)
            Text("건너뛰기")
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
  SidebarView(
    viewModel: MainViewModel(),
    sidebarState: $sidebarState,
    position: .constant(.leading)
  )
}
