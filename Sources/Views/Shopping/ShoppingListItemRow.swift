import SwiftUI

struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(item.isChecked ? Theme.primary : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)

            // Item info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayString)
                    .font(.system(.body, design: .rounded))
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let cost = item.estimatedCost {
                Text(cost.asDollarString)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}
