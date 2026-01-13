import SwiftUI
import SwiftData

/// Tinder-style swipe card for voting on recipes
struct VotingCardView: View {

    // MARK: - Properties

    let recipe: Recipe
    let onVote: (VoteType) -> Void

    // MARK: - State

    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    // MARK: - Constants

    private let swipeThreshold: CGFloat = 100
    private let rotationMultiplier: Double = 0.1

    // MARK: - Body

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)

            VStack(alignment: .leading, spacing: 0) {
                // Recipe image
                recipeImage
                    .frame(height: 300)
                    .clipped()

                // Recipe info
                VStack(alignment: .leading, spacing: 12) {
                    Text(recipe.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    HStack(spacing: 16) {
                        Label("\(recipe.totalTime) min", systemImage: "clock")
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                        Label(recipe.difficulty.rawValue.capitalized, systemImage: "chart.bar")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if let description = recipe.recipeDescription {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }

                    // Tags
                    if !recipe.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }

            // Swipe indicators
            swipeIndicators
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(20)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .opacity(opacity)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width) * rotationMultiplier
                }
                .onEnded { gesture in
                    handleSwipeEnd(translation: gesture.translation)
                }
        )
    }

    // MARK: - Subviews

    private var recipeImage: some View {
        Group {
            if let imageData = recipe.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = recipe.imageURL,
                      let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var swipeIndicators: some View {
        ZStack {
            // Left swipe - Dislike
            if offset.width < -20 {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .opacity(min(abs(offset.width) / swipeThreshold, 1.0))
                            .padding(40)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // Right swipe - Like
            if offset.width > 20 {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .opacity(min(offset.width / swipeThreshold, 1.0))
                            .padding(40)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // Up swipe - Super Like
            if offset.height < -20 {
                VStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.pink)
                        .opacity(min(abs(offset.height) / swipeThreshold, 1.0))
                        .padding(40)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Private Methods

    private func handleSwipeEnd(translation: CGSize) {
        let horizontalSwipe = abs(translation.width) > abs(translation.height)

        if horizontalSwipe {
            // Right swipe - Like
            if translation.width > swipeThreshold {
                animateSwipe(direction: .right, voteType: .like)
            }
            // Left swipe - Dislike
            else if translation.width < -swipeThreshold {
                animateSwipe(direction: .left, voteType: .dislike)
            } else {
                // Return to center
                withAnimation(.spring()) {
                    offset = .zero
                    rotation = 0
                }
            }
        } else {
            // Up swipe - Super Like
            if translation.height < -swipeThreshold {
                animateSwipe(direction: .up, voteType: .superLike)
            } else {
                // Return to center
                withAnimation(.spring()) {
                    offset = .zero
                    rotation = 0
                }
            }
        }
    }

    private func animateSwipe(direction: SwipeDirection, voteType: VoteType) {
        let finalOffset: CGSize
        let finalRotation: Double

        switch direction {
        case .left:
            finalOffset = CGSize(width: -500, height: offset.height)
            finalRotation = -20
        case .right:
            finalOffset = CGSize(width: 500, height: offset.height)
            finalRotation = 20
        case .up:
            finalOffset = CGSize(width: 0, height: -500)
            finalRotation = 0
        }

        withAnimation(.easeOut(duration: 0.3)) {
            offset = finalOffset
            rotation = finalRotation
            opacity = 0
            scale = 0.8
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Trigger vote callback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onVote(voteType)
        }
    }
}

// MARK: - Supporting Types

enum SwipeDirection {
    case left, right, up
}

// MARK: - Action Buttons View

struct VotingActionButtons: View {
    let onVeto: () -> Void
    let onDislike: () -> Void
    let onOk: () -> Void
    let onLike: () -> Void
    let onSuperLike: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Veto
            Button(action: onVeto) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                    .frame(width: 50, height: 50)
                    .background(.red.opacity(0.1))
                    .clipShape(Circle())
            }

            // Dislike
            Button(action: onDislike) {
                Image(systemName: "hand.thumbsdown.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .frame(width: 60, height: 60)
                    .background(.orange.opacity(0.1))
                    .clipShape(Circle())
            }

            // OK
            Button(action: onOk) {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(width: 60, height: 60)
                    .background(.gray.opacity(0.1))
                    .clipShape(Circle())
            }

            // Like
            Button(action: onLike) {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .frame(width: 70, height: 70)
                    .background(.green.opacity(0.1))
                    .clipShape(Circle())
            }

            // Super Like
            Button(action: onSuperLike) {
                Image(systemName: "heart.fill")
                    .font(.title)
                    .foregroundColor(.pink)
                    .frame(width: 50, height: 50)
                    .background(.pink.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    let recipe = Recipe(
        title: "Classic Spaghetti Carbonara",
        instructions: "Cook pasta, fry pancetta, mix with egg and cheese...",
        recipeDescription: "A traditional Italian pasta dish with eggs, cheese, and pancetta",
        prepTime: 10,
        cookTime: 20,
        servings: 4,
        difficulty: .medium,
        cuisine: "Italian",
        tags: ["pasta", "italian", "quick", "comfort-food"]
    )

    return ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VotingCardView(recipe: recipe) { voteType in
            print("Voted: \(voteType)")
        }
        .padding(20)
    }
}
