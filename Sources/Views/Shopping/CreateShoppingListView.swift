import SwiftUI
import SwiftData

struct CreateShoppingListView: View {
    let familyGroup: FamilyGroup?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \MealSession.startDate, order: .reverse)
    private var mealSessions: [MealSession]

    @State private var listName = ""
    @State private var storeName = ""

    private var finalizedSessions: [MealSession] {
        mealSessions.filter { $0.status == .finalized || $0.status == .active }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("List Details") {
                    TextField("List Name", text: $listName)
                    TextField("Store (Optional)", text: $storeName)
                }

                Section("Generate From") {
                    Button("Current Meal Plan") {
                        createFromMealPlan()
                    }
                    .disabled(finalizedSessions.isEmpty)

                    Button("Start Empty") {
                        createEmptyList()
                    }
                }
            }
            .navigationTitle("New Shopping List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func createFromMealPlan() {
        guard let session = finalizedSessions.first else { return }

        let list = ShoppingList.createFrom(mealSession: session, context: modelContext)

        if !listName.isEmpty {
            list.name = listName
        }
        if !storeName.isEmpty {
            list.store = storeName
        }
        list.familyGroup = familyGroup

        modelContext.insert(list)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to create list from meal plan: \(error)")
        }
    }

    private func createEmptyList() {
        let list = ShoppingList(
            name: listName.isEmpty ? "Shopping List" : listName,
            store: storeName.isEmpty ? nil : storeName
        )
        list.familyGroup = familyGroup

        modelContext.insert(list)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to create list: \(error)")
        }
    }
}
