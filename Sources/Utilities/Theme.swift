import SwiftUI

/// Centralized design system for MealMeld
enum Theme {
    // MARK: - Colors
    
    static let primary = Color(red: 0.95, green: 0.35, blue: 0.37) // Refined Coral
    static let secondary = Color(red: 0.28, green: 0.28, blue: 0.28) // Deep Charcoal
    static let accent = Color(red: 1.0, green: 0.70, blue: 0.0) // Amber
    static let background = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    
    // MARK: - Spacing
    
    static let padding: CGFloat = 20
    static let spacing: CGFloat = 16
    static let cornerRadius: CGFloat = 14 // Slightly more modern
    
    // MARK: - Typography (Semantic)
    
    static func titleFont() -> Font {
        .system(.title, design: .rounded).weight(.bold)
    }
    
    static func subtitleFont() -> Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }
    
    static func bodyFont() -> Font {
        .system(.body, design: .rounded)
    }
    
    // MARK: - Effects
    
    static let softShadow = Shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    /// Applies the standard card style with theme-consistent properties
    func standardCard() -> some View {
        self
            .padding(Theme.padding)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Theme.softShadow.color, radius: Theme.softShadow.radius, x: Theme.softShadow.x, y: Theme.softShadow.y)
    }
    
    /// Modern list row styling
    func elegantRow() -> some View {
        self
            .padding(.vertical, 8)
            .padding(.horizontal, Theme.padding)
            .background(Theme.cardBackground)
            .cornerRadius(10)
    }
    
    /// Applies a primary gradient background (useful for buttons)
    func primaryGradient() -> some View {
        self.background(
            LinearGradient(
                colors: [Theme.primary, Theme.primary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
