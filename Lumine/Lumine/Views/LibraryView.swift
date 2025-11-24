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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
              viewModel.send(.viewAction(.didSelectVideo(url)))
            }
          } label: {
            VStack(alignment: .leading) {
              ThumbnailView(url: url)
                .frame(height: 100) // Approximate height for 16:9 aspect ratio within grid
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .overlay {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                }
              .matchedGeometryEffect(id: url, in: animation)

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
    .contentShape(Rectangle()) // Ensure the entire area is hit-testable for drops
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
