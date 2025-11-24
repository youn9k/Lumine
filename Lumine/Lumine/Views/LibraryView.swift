import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
  @Bindable var viewModel: MainViewModel
  var animation: Namespace.ID

  let columns = [
    GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
  ]

  var body: some View {
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
                .clipShape(RoundedRectangle(cornerRadius: 12)) // 오버레이에서 넘친 이미지 부분을 자름
                .contentShape(RoundedRectangle(cornerRadius: 12)) // Hit testing 영역을 설정
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
    .background(Color.black.opacity(0.05))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle()) // Hit testing 영역을 설정
    .onDrop(of: [.movie, .video, .fileURL, .content, .item], isTargeted: nil) { providers in
      viewModel.fileService.processDroppedItems(providers: providers) { urls in
        if !urls.isEmpty {
          viewModel.send(.viewAction(.didDropFiles(urls)))
        }
      }
      return true
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
