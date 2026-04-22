import SwiftUI

struct ShoppingView: View {
    @ObservedObject var viewModel: PantryViewModel
    @State private var selection: Set<String> = []
    @State private var alertMessage: String? = nil
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color.teal.opacity(0.22), Color.blue.opacity(0.10), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shopping Planner")
                                .font(.title2.weight(.bold))
                            Text("Collect missing ingredients and send them to Apple Reminders.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThinMaterial))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        Text("Suggested Shopping Items")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        ForEach(groupedShoppingItems, id: \.id) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.displayName)
                                        .font(.title3.weight(.bold))
                                    Text("Used by: \(item.cocktailNames.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Button(action: { selection.insert(item.id) }) {
                                    Label("Add", systemImage: "plus.circle.fill")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .padding(.horizontal, 20)
                        }

                        Text("Selected Ingredients")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        ForEach(Array(selection), id: \.self) { id in
                            HStack {
                                Text(viewModel.ingredientsDict[id]?.displayName ?? id)
                                Spacer()
                                Button(action: { selection.remove(id) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .padding(.horizontal, 20)
                        }

                        if selection.isEmpty {
                            Text("No ingredients selected yet")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 120)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .bottom) {
                Button(action: sendToReminders) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Send \(selection.count) to Apple Reminders")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(selection.isEmpty ? Color.gray.opacity(0.45) : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .disabled(selection.isEmpty)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Shopping")
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Reminders"), message: Text(alertMessage ?? ""), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func sendToReminders() {
        let reminderService = ReminderService()
        let items = Array(selection)
        reminderService.createReminders(listName: "Cocktail Shopping", items: items) { result in
            switch result {
            case .success:
                alertMessage = "Reminders created (may be in default list)."
            case .failure(let err):
                alertMessage = "Failed to create reminders: \(err.localizedDescription)"
            }
            showingAlert = true
        }
    }

    private var groupedShoppingItems: [(id: String, displayName: String, cocktailNames: [String])] {
        let almostThere = viewModel.recommendationResults().filter { !$0.canMake }
        let grouped = viewModel.aggregatedMissing(for: almostThere)

        return grouped
            .map { ingredientId, cocktails in
                (
                    id: ingredientId,
                    displayName: viewModel.ingredientsDict[ingredientId]?.displayName ?? ingredientId,
                    cocktailNames: Array(Set(cocktails)).sorted()
                )
            }
            .sorted { $0.displayName < $1.displayName }
    }
}

struct ShoppingView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingView(viewModel: PantryViewModel())
    }
}
