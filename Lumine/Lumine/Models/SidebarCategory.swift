import Foundation

enum SidebarCategory: String, CaseIterable, Identifiable {
    case allVideos = "All Videos"
    case favorites = "Favorites"
    case playlists = "Playlists"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .allVideos: return "film"
        case .favorites: return "heart"
        case .playlists: return "list.bullet"
        }
    }
}
