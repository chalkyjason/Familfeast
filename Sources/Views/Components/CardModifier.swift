import SwiftUI

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: shadowRadius, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 8) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}
