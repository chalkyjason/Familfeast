import SwiftUI

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.cornerRadius
    var shadowRadius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .padding(Theme.padding)
            .background(Theme.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: Theme.softShadow.color,
                radius: Theme.softShadow.radius,
                x: Theme.softShadow.x,
                y: Theme.softShadow.y
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = Theme.cornerRadius, shadowRadius: CGFloat = 8) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}
