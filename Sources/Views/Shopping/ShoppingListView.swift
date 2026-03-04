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
                Button(action: { showingNewList = true }) {
                    Image(systemName: "plus")
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
        .padding()
        .background(.regularMaterial)
    }

    private func shoppingListContent(_ list: ShoppingList) -> some View {
        VStack(spacing: 0) {
            // List header with stats
            listHeaderCard(list)

            // Items by category
            if let items = list.items, !items.isEmpty {
                categorizedItemsList(items)
            } else {
                Text("No items in this list")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
                        .foregroundColor(.orange)
                }

                ProgressView(value: list.completionPercentage() / 100.0)
                    .tint(.orange)
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
                    Text("Mark All Complete")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(.white)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func categorizedItemsList(_ items: [ShoppingListItem]) -> some View {
        List {
            // Group items by category
            let grouped = Dictionary(grouping: items) { $0.category }
            let sortedCategories = grouped.keys.sorted { $0.displayName < $1.displayName }

            ForEach(sortedCategories, id: \.self) { category in
                Section {
                    ForEach(grouped[category] ?? []) { item in
                        ShoppingListItemRow(item: item) {
                            toggleItem(item)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.displayName)
                    }
                    .font(.headline)
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
