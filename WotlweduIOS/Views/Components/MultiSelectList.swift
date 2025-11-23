import SwiftUI

struct MultiSelectList<Item: Identifiable & Hashable & NamedEntity>: View {
    let title: String
    let items: [Item]
    @Binding var selection: Set<Item.ID>

    var body: some View {
        Section(title) {
            ForEach(items, id: \.id) { item in
                HStack {
                    Text(item.name ?? "Unnamed")
                    Spacer()
                    if selection.contains(item.id) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggle(item.id)
                }
            }
        }
    }

    private func toggle(_ id: Item.ID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}
