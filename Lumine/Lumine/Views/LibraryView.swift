import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
  @Bindable var viewModel: MainViewModel
  var animation: Namespace.ID
  @State private var isImporting: Bool = false

  let columns = [
    GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
  ]

  var body: some View {
    ZStack {
      if viewModel.fileService.files.isEmpty {
        emptyStateView
      } else {
        videoGridView
      }
    }
    .fileImporter(
      isPresented: $isImporting,
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
    .background(Color.black.opacity(0.05))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle())
    .onDrop(of: [.movie, .video, .fileURL], isTargeted: nil) { providers in
      viewModel.fileService.processDroppedItems(providers: providers) { urls in
        if !urls.isEmpty {
          viewModel.send(.viewAction(.didDropFiles(urls)))
        }
      }
      return true
    }
  }

  private var emptyStateView: some View {
    ZStack {
      // Drop Zone Indicator
      RoundedRectangle(cornerRadius: 24)
        .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [10]))
        .foregroundStyle(.secondary.opacity(0.3))
        .padding(20)
        .overlay(alignment: .center) {
          VStack(spacing: 16) {
            Image(systemName: "arrow.down.doc")
              .font(.system(size: 60))
            Text("여기에 끌어다 놓으세요")
              .font(.title2)
          }
          .foregroundStyle(.secondary)
        }

      // Play Button
      VStack {
        Spacer()
        Button {
          isImporting = true
        } label: {
          Text("바로 재생하기")
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 16)
            .frame(maxWidth: 200)
            .background(AppColors.skyBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: AppColors.skyBlue.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 140)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var videoGridView: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(viewModel.fileService.files, id: \.self) { url in
          Button {
            viewModel.send(.viewAction(.didSelectVideo(url)))
          } label: {
            VStack(alignment: .leading) {
              Color.clear
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay {
                  ThumbnailView(url: url)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

              Text(url.lastPathComponent)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundStyle(.primary)
            }
          }
          .buttonStyle(.plain)
        }
      }
      .padding()
    }
  }
}

#Preview {
  @Previewable @Namespace var animation

  ZStack {
    Rectangle()
      .fill(Color.lavender)
    LibraryView(viewModel: MainViewModel(), animation: animation)
      .padding(40)
  }
}
