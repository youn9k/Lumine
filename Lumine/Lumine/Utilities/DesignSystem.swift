import SwiftUI

enum AppColors {
    // Pastel Palette
  static let lavender = Color.lavender
  static let mint = Color.mintGreen
  static let peach = Color.peach
  static let skyBlue = Color.skyBlue
    
    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
          lavender,
          skyBlue,
          peach
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum LayoutConstants {
    // Sidebar
    static let sidebarCompactWidth: CGFloat = 80
    static let sidebarExpandedWidth: CGFloat = 200
    static let sidebarPadding: CGFloat = 16
    static let sidebarCornerRadius: CGFloat = 24
    
    // Content Card
    static let cardCornerRadius: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let cardShadowRadius: CGFloat = 10
    static let cardShadowY: CGFloat = 5
}
