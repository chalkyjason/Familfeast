import SwiftUI
import SwiftData

struct CuisinePreferencesView: View {

    // MARK: - Properties

    let familyGroup: FamilyGroup

    @Environment(\.modelContext) private var modelContext

    // MARK: - Constants

    private let cuisineOptions = [
        "Italian", "Mexican", "Thai", "Chinese", "Japanese",
        "Indian", "Mediterranean", "American", "French", "Greek",
        "Korean", "Vietnamese", "Ethiopian", "Brazilian", "Spanish"
    ]

    // MARK: - Body

    var body: some View {
        List {
            if let members = familyGroup.members, !members.isEmpty {
                ForEach(members) { member in
                    Section(member.displayName) {
                        ForEach(cuisineOptions, id: \.self) { cuisine in
                            Toggle(cuisine, isOn: Binding(
                                get: { member.cuisinePreferences.contains(cuisine) },
                                set: { isOn in
                                    if isOn {
                                        if !member.cuisinePreferences.contains(cuisine) {
                                            member.cuisinePreferences.append(cuisine)
                                        }
                                    } else {
                                        member.cuisinePreferences.removeAll { $0 == cuisine }
                                    }
                                    try? modelContext.save()
                                }
                            ))
                            .font(.body)
                        }
                    }
                }
            } else {
                Text("No family members yet")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Cuisine Preferences")
    }
}
