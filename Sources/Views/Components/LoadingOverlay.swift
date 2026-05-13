import SwiftUI

/// A full-screen or partial loading overlay
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
}

extension View {
    func loadingOverlay(isShowing: Bool, message: String = "Loading...") -> some View {
        ZStack {
            self
            
            if isShowing {
                LoadingOverlay(message: message)
                    .transition(.opacity.animation(.easeInOut))
            }
        }
    }
}

#Preview {
    Text("Background Content")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue)
        .loadingOverlay(isShowing: true, message: "Generating Recipes...")
}
