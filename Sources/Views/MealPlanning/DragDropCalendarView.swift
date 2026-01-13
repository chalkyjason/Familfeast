import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DragDropCalendarView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let mealSession: MealSession
    @Binding var selectedRecipes: [Recipe]

    // MARK: - State

    @State private var draggedRecipe: Recipe?
    @State private var weekDays: [Date] = []

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Calendar grid
                    calendarGrid

                    // Available recipes section
                    availableRecipesSection
                }
                .padding()
            }
        }
        .onAppear {
            setupWeekDays()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Drag & Drop Meal Schedule")
                .font(.headline)

            Text("Drag recipes from the bottom to schedule them")
                .font(.caption)
                .foregroundColor(.secondary)

            // Budget indicator
            if let budget = mealSession.budgetLimit {
                BudgetIndicator(
                    estimated: mealSession.calculateEstimatedCost(),
                    budget: budget
                )
            }
        }
        .padding()
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 1), spacing: 12) {
            ForEach(weekDays, id: \.self) { date in
                DayCard(
                    date: date,
                    scheduledMeal: getScheduledMeal(for: date),
                    onDrop: { recipe in
                        scheduleMeal(recipe: recipe, on: date)
                    },
                    onRemove: {
                        removeMeal(for: date)
                    }
                )
            }
        }
    }

    private var availableRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Available Recipes")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableRecipes) { recipe in
                        RecipeCard(recipe: recipe, isDragged: draggedRecipe?.id == recipe.id)
                            .draggable(recipe) {
                                RecipePreview(recipe: recipe)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Computed Properties

    private var availableRecipes: [Recipe] {
        // Show winning recipes that haven't been scheduled yet
        let scheduledRecipeIDs = Set((mealSession.scheduledMeals ?? []).compactMap { $0.recipe?.id })
        return selectedRecipes.filter { !scheduledRecipeIDs.contains($0.id) }
    }

    // MARK: - Methods

    private func setupWeekDays() {
        var days: [Date] = []
        var current = mealSession.startDate

        while current <= mealSession.endDate {
            days.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }

        weekDays = days
    }

    private func getScheduledMeal(for date: Date) -> ScheduledMeal? {
        mealSession.scheduledMeals?.first { meal in
            Calendar.current.isDate(meal.scheduledDate, inSameDayAs: date)
        }
    }

    private func scheduleMeal(recipe: Recipe, on date: Date) {
        // Remove existing meal for this date if any
        if let existing = getScheduledMeal(for: date) {
            modelContext.delete(existing)
        }

        // Create new scheduled meal
        let scheduledMeal = ScheduledMeal(
            scheduledDate: date,
            mealType: recipe.mealType
        )
        scheduledMeal.recipe = recipe
        scheduledMeal.mealSession = mealSession

        modelContext.insert(scheduledMeal)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        try? modelContext.save()
    }

    private func removeMeal(for date: Date) {
        if let existing = getScheduledMeal(for: date) {
            modelContext.delete(existing)

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            try? modelContext.save()
        }
    }
}

// MARK: - Supporting Views

struct DayCard: View {
    let date: Date
    let scheduledMeal: ScheduledMeal?
    let onDrop: (Recipe) -> Void
    let onRemove: () -> Void

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayOfWeek)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if scheduledMeal != nil {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Meal content
            if let meal = scheduledMeal, let recipe = meal.recipe {
                HStack(spacing: 12) {
                    // Recipe thumbnail
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .foregroundColor(.gray)
                        }

                    // Recipe info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Label("\(recipe.totalTime)m", systemImage: "clock")
                            Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        if let cost = recipe.totalEstimatedCost {
                            Text("$\(String(format: "%.2f", Double(cost) / 100.0))")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()
                }
            } else {
                // Drop zone
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isTargeted ? Color.blue : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [5])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isTargeted ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    )
                    .frame(height: 100)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(isTargeted ? .blue : .gray)

                            Text("Drop recipe here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .dropDestination(for: Recipe.self) { items, location in
            guard let recipe = items.first else { return false }
            onDrop(recipe)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    var isDragged: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recipe image
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.2))
                .frame(width: 140, height: 100)
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.title)
                        .foregroundColor(.gray.opacity(0.5))
                }

            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .frame(width: 140, alignment: .leading)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("\(recipe.totalTime)m")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let cost = recipe.totalEstimatedCost {
                    Text("$\(String(format: "%.2f", Double(cost) / 100.0))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isDragged ? 0.5 : 1.0)
    }
}

struct RecipePreview: View {
    let recipe: Recipe

    var body: some View {
        VStack {
            Text(recipe.title)
                .font(.caption)
                .padding(8)
                .background(.white)
                .cornerRadius(8)
                .shadow(radius: 4)
        }
    }
}

struct BudgetIndicator: View {
    let estimated: Int
    let budget: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("$\(String(format: "%.2f", Double(budget) / 100.0))")
                    .font(.headline)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Estimated")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("$\(String(format: "%.2f", Double(estimated) / 100.0))")
                    .font(.headline)
                    .foregroundColor(estimated > budget ? .red : .green)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(estimated > budget ? Color.red : Color.green)
                        .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(estimated) / CGFloat(budget)), height: 8)
                }
            }
            .frame(width: 100, height: 8)
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Transferable Conformance

extension Recipe: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .recipe)
    }
}

extension UTType {
    static let recipe = UTType(exportedAs: "com.familyfeast.recipe")
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: MealSession.self, Recipe.self, ScheduledMeal.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let session = MealSession(
        name: "Week of Jan 15",
        startDate: Date(),
        endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
        budgetLimit: 15000
    )

    let recipe1 = Recipe(title: "Spaghetti Carbonara", instructions: "Cook...", prepTime: 10, cookTime: 20)
    let recipe2 = Recipe(title: "Chicken Stir Fry", instructions: "Stir fry...", prepTime: 15, cookTime: 15)

    container.mainContext.insert(session)
    container.mainContext.insert(recipe1)
    container.mainContext.insert(recipe2)

    return DragDropCalendarView(mealSession: session, selectedRecipes: .constant([recipe1, recipe2]))
        .modelContainer(container)
}
