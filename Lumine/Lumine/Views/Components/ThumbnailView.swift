import SwiftUI

struct ThumbnailView: View {
    let url: URL
    @State private var image: Image?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .layoutPriority(-1)
            } else {
                ZStack {
                    Color.gray.opacity(0.3)
                    
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        guard image == nil else { return }
        isLoading = true
        
        do {
            if let platformImage = try await ThumbnailService.shared.generateThumbnail(for: url) {
                #if os(macOS)
                self.image = Image(nsImage: platformImage)
                #else
                self.image = Image(uiImage: platformImage)
                #endif
            }
        } catch {
            print("Failed to load thumbnail: \(error)")
        }
        
        isLoading = false
    }
}
