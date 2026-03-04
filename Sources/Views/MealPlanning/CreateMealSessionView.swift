import SwiftUI
import SwiftData

struct CreateMealSessionView: View {
    let familyGroup: FamilyGroup

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var numberOfMeals = 7
    @State private var budgetLimit = ""
    @State private var selectedRecipeIDs: Set<UUID> = []
    @State private var showingRecipePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    TextField("Name (e.g. Week of Jan 15)", text: $name)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section("Meals") {
                    Stepper("Number of meals: \(numberOfMeals)", value: $numberOfMeals, in: 1...21)
                    TextField("Budget (optional, e.g. 150.00)", text: $budgetLimit)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }

                Section("Candidate Recipes") {
                    Button(action: { showingRecipePicker = true }) {
                        HStack {
                            Text("Select Recipes")
                            Spacer()
                            Text("\(selectedRecipeIDs.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Meal Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createSession() }
                }
            }
            .sheet(isPresented: $showingRecipePicker) {
                RecipePickerView(selectedRecipeIDs: $selectedRecipeIDs)
            }
        }
    }

    private func createSession() {
        let sessionName = name.isEmpty ? "Week of \(startDate.formatted(date: .abbreviated, time: .omitted))" : name

        let session = MealSession(
            name: sessionName,
            startDate: startDate,
            endDate: endDate,
            numberOfMeals: numberOfMeals
        )

        // Parse budget
        if let budgetValue = Double(budgetLimit), budgetValue > 0 {
            session.budgetLimit = Int(budgetValue * 100)
        }

        session.familyGroup = familyGroup

        // Fetch selected recipes and attach as candidates
        if !selectedRecipeIDs.isEmpty {
            let allIDs = selectedRecipeIDs
            var descriptor = FetchDescriptor<Recipe>()
            descriptor.predicate = #Predicate<Recipe> { recipe in
                allIDs.contains(recipe.id)
            }
            if let recipes = try? modelContext.fetch(descriptor) {
                session.candidateRecipes = recipes
                session.status = .voting
            }
        }

        modelContext.insert(session)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to create session: \(error)")
        }
    }
}
