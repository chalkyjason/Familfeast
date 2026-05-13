import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    var onFavoriteToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            // High-quality image thumbnail
            recipeImage
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Label("\(recipe.totalTime)m", systemImage: "clock")
                    Text("•")
                    Text(recipe.difficulty.rawValue.capitalized)
                    Text("•")
                    Text(recipe.mealType.rawValue.capitalized)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if !recipe.tags.isEmpty {
                    Text(recipe.tags.prefix(2).joined(separator: ", "))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.primary.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Spacer()

            if let onToggle = onFavoriteToggle {
                Button(action: onToggle) {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(recipe.isFavorite ? .red : .gray.opacity(0.4))
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private var recipeImage: some View {
        Group {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
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
            Color.gray.opacity(0.1)
            Image(systemName: "fork.knife")
                .foregroundColor(.gray.opacity(0.3))
        }
    }
}
