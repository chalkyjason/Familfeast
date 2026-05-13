import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct ShoppingListView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let familyGroup: FamilyGroup?

    // MARK: - Queries

    @Query(sort: \ShoppingList.createdAt, order: .reverse)
    private var shoppingLists: [ShoppingList]

    // MARK: - State

    @State private var selectedList: ShoppingList?
    @State private var showingNewList = false
    @State private var newItemName = ""
    @State private var activeError: AppError?
    @State private var showCheckedItems = true

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // List selector
            if !shoppingLists.isEmpty {
                listPicker
            }

            if let list = selectedList {
                shoppingListContent(list)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Shopping List")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if let list = selectedList, let items = list.items, items.contains(where: { $0.isChecked }) {
                        Button(action: { clearCompleted(list) }) {
                            Image(systemName: "trash")
                        }
                    }
                    
                    Button(action: { showingNewList = true }) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewList) {
            CreateShoppingListView(familyGroup: familyGroup)
        }
        .onAppear {
            if selectedList == nil {
                selectedList = activeShoppingList
            }
        }
    }

    // MARK: - Subviews

    private var listPicker: some View {
        Picker("Shopping List", selection: $selectedList) {
            ForEach(shoppingLists) { list in
                Text(list.name).tag(list as ShoppingList?)
            }
        }
        .pickerStyle(.menu)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }

    private func shoppingListContent(_ list: ShoppingList) -> some View {
        VStack(spacing: 0) {
            // List header with stats
            listHeaderCard(list)
                .padding()

            // Quick add field
            quickAddSection(list)
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Items by category
            if let items = list.items, !items.isEmpty {
                categorizedItemsList(list, items: items)
            } else {
                Spacer()
                Text("No items in this list")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    private func quickAddSection(_ list: ShoppingList) -> some View {
        HStack {
            TextField("Add item (e.g. Milk)", text: $newItemName)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Theme.cardBackground)
                .cornerRadius(10)
                .onSubmit {
                    addItem(to: list)
                }

            Button(action: { addItem(to: list) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(Theme.primary)
            }
            .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func listHeaderCard(_ list: ShoppingList) -> some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(list.remainingItems()) items remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(list.completionPercentage()))%")
                        .font(.headline)
                        .foregroundColor(Theme.primary)
                }

                ProgressView(value: list.completionPercentage() / 100.0)
                    .tint(Theme.primary)
            }

            // Cost info
            if let estimated = list.estimatedTotal {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Estimated Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(estimated.asDollarString)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    if let actual = list.actualTotal {
                        VStack(alignment: .trailing) {
                            Text("Actual Spent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(actual.asDollarString)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(actual > estimated ? .red : .green)
                        }
                    }
                }
            }

            // Complete button
            if !list.isComplete {
                Button(action: { completeList(list) }) {
                    Text("Archive List")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primary.gradient)
                        .cornerRadius(12)
                }
            }
        }
        .cardStyle()
    }

    private func categorizedItemsList(_ list: ShoppingList, items: [ShoppingListItem]) -> some View {
        List {
            let uncheckedItems = items.filter { !$0.isChecked }
            let checkedItems = items.filter { $0.isChecked }

            // Group unchecked items by category
            let grouped = Dictionary(grouping: uncheckedItems) { $0.category }
            let sortedCategories = grouped.keys.sorted { $0.displayName < $1.displayName }

            ForEach(sortedCategories, id: \.self) { category in
                Section {
                    ForEach(grouped[category] ?? []) { item in
                        ShoppingListItemRow(item: item) {
                            toggleItem(item)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteItem(item, from: list)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.displayName)
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primary)
                    .textCase(nil)
                }
            }

            // Checked items section
            if !checkedItems.isEmpty {
                Section {
                    if showCheckedItems {
                        ForEach(checkedItems) { item in
                            ShoppingListItemRow(item: item) {
                                toggleItem(item)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteItem(item, from: list)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Button(action: { withAnimation { showCheckedItems.toggle() } }) {
                        HStack {
                            Text("Checked Items (\(checkedItems.count))")
                            Spacer()
                            Image(systemName: showCheckedItems ? "chevron.down" : "chevron.right")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "cart.badge.plus",
            title: "No Shopping Lists",
            subtitle: "Create a shopping list from your meal plans",
            buttonTitle: "Create List",
            buttonColor: .orange
        ) {
            showingNewList = true
        }
    }

    // MARK: - Computed Properties

    private var activeShoppingList: ShoppingList? {
        shoppingLists.first { !$0.isComplete }
    }

    // MARK: - Methods

    private func addItem(to list: ShoppingList) {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        // Use the basic parser from Ingredient extension if available
        let item: ShoppingListItem
        if let parsed = Ingredient.parse(from: name) {
            item = ShoppingListItem(
                name: parsed.name,
                quantity: parsed.quantity,
                unit: parsed.unit,
                category: parsed.category
            )
        } else {
            item = ShoppingListItem(name: name, quantity: 1, unit: "unit")
        }

        item.shoppingList = list
        modelContext.insert(item)
        newItemName = ""

        do {
            try modelContext.save()
        } catch {
            print("Failed to add item: \(error)")
        }
    }

    private func deleteItem(_ item: ShoppingListItem, from list: ShoppingList) {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete item: \(error)")
        }
    }

    private func clearCompleted(_ list: ShoppingList) {
        guard let items = list.items else { return }
        let completed = items.filter { $0.isChecked }
        
        for item in completed {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to clear completed: \(error)")
        }
    }

    private func toggleItem(_ item: ShoppingListItem) {
        item.toggle()

        // Haptic feedback
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif

        do {
            try modelContext.save()
        } catch {
            print("Failed to save item: \(error)")
        }
    }

    private func completeList(_ list: ShoppingList) {
        list.isComplete = true

        do {
            try modelContext.save()
        } catch {
            print("Failed to complete list: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShoppingListView(familyGroup: nil)
            .modelContainer(for: ShoppingList.self, inMemory: true)
    }
}
