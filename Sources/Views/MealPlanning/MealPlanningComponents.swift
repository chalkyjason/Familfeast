import SwiftUI

struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(12)
    }

    private var backgroundColor: Color {
        switch status {
        case .planning: return .blue
        case .voting: return .green
        case .finalizing: return .orange
        case .finalized: return .purple
        case .active: return .pink
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

struct ScheduledMealRow: View {
    let meal: ScheduledMeal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.dayOfWeek)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(meal.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)

            if let recipe = meal.recipe {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .foregroundColor(.gray)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Text("\(recipe.totalTime) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            } else {
                Text("No recipe assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CandidateRecipeCard: View {
    let recipe: Recipe
    let votes: [Vote]

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.gray)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(1)

                // Vote counts
                let recipeVotes = votes.filter { $0.recipe?.id == recipe.id }
                let voteCounts = recipeVotes.countByType()

                HStack(spacing: 8) {
                    if let likes = voteCounts[.like] {
                        Label("\(likes)", systemImage: "hand.thumbsup.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    if let dislikes = voteCounts[.dislike] {
                        Label("\(dislikes)", systemImage: "hand.thumbsdown.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Text("Score: \(recipeVotes.bordaScore())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
