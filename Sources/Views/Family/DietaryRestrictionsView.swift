import SwiftUI
import SwiftData

struct DietaryRestrictionsView: View {

    // MARK: - Properties

    let familyGroup: FamilyGroup

    @Environment(\.modelContext) private var modelContext

    // MARK: - Constants

    private let dietaryOptions = [
        "Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free",
        "Halal", "Kosher", "Keto", "Paleo", "Low-Sodium"
    ]

    private let allergenOptions = [
        "Peanuts", "Tree Nuts", "Shellfish", "Fish",
        "Milk", "Eggs", "Wheat", "Soy", "Sesame"
    ]

    // MARK: - Body

    var body: some View {
        List {
            if let members = familyGroup.members, !members.isEmpty {
                ForEach(members) { member in
                    Section(member.displayName) {
                        DisclosureGroup("Dietary Restrictions") {
                            ForEach(dietaryOptions, id: \.self) { option in
                                Toggle(option, isOn: Binding(
                                    get: { member.dietaryRestrictions.contains(option) },
                                    set: { isOn in
                                        if isOn {
                                            if !member.dietaryRestrictions.contains(option) {
                                                member.dietaryRestrictions.append(option)
                                            }
                                        } else {
                                            member.dietaryRestrictions.removeAll { $0 == option }
                                        }
                                        try? modelContext.save()
                                    }
                                ))
                                .font(.body)
                            }
                        }

                        DisclosureGroup("Allergens") {
                            ForEach(allergenOptions, id: \.self) { option in
                                Toggle(option, isOn: Binding(
                                    get: { member.allergens.contains(option) },
                                    set: { isOn in
                                        if isOn {
                                            if !member.allergens.contains(option) {
                                                member.allergens.append(option)
                                            }
                                        } else {
                                            member.allergens.removeAll { $0 == option }
                                        }
                                        try? modelContext.save()
                                    }
                                ))
                                .font(.body)
                            }
                        }
                    }
                }
            } else {
                Text("No family members yet")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Dietary Restrictions")
    }
}
