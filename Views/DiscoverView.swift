import SwiftUI

struct DiscoverView: View {
    @ObservedObject var viewModel: PantryViewModel
    @State private var selectedMode: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color.orange.opacity(0.22), Color.pink.opacity(0.12), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Mode", selection: $selectedMode) {
                            Text("Can Make").tag(0)
                            Text("Almost There").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        let items = filteredResults

                        if items.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("No matches yet")
                                    .font(.headline)
                                Text("Add more pantry ingredients to unlock recommendations.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
                            .padding(.horizontal, 20)
                        } else {
                            ForEach(items) { result in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top) {
                                        Image(systemName: result.canMake ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                            .foregroundColor(result.canMake ? .green : .orange)
                                            .font(.title2)

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(result.cocktail.name)
                                                .font(.headline)

                                            HStack(spacing: 6) {
                                                ForEach(result.cocktail.flavorTags ?? [], id: \.self) { tag in
                                                    Text(tag.capitalized)
                                                        .font(.caption)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color(.tertiarySystemBackground))
                                                        .cornerRadius(10)
                                                }
                                            }
                                        }

                                        Spacer()

                                        Text(result.canMake ? "Ready" : "Missing \(result.missing.count)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(result.canMake ? .green : .orange)
                                    }

                                    if result.canMake {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Ingredients")
                                                .font(.subheadline.weight(.semibold))
                                            ForEach(result.cocktail.ingredients.filter { !($0.optional ?? false) }, id: \.ingredientId) { ing in
                                                HStack(alignment: .top, spacing: 6) {
                                                    Text("•")
                                                        .foregroundColor(.secondary)
                                                    Text(
                                                        ing.amount?.isEmpty == false
                                                        ? "\(ing.amount ?? "") \(viewModel.ingredientsDict[ing.ingredientId]?.displayName ?? ing.ingredientId)"
                                                        : (viewModel.ingredientsDict[ing.ingredientId]?.displayName ?? ing.ingredientId)
                                                    )
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }

                                    if !result.missing.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(result.missing, id: \.self) { m in
                                                    Text(viewModel.ingredientsDict[m]?.displayName ?? m)
                                                        .font(.caption)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 5)
                                                        .background(Color.red.opacity(0.10))
                                                        .foregroundColor(.red)
                                                        .cornerRadius(10)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var filteredResults: [MatchResult] {
        let all = viewModel.recommendationResults()
        if selectedMode == 0 {
            return all.filter { $0.canMake }
        }
        return all.filter { !$0.canMake }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(viewModel: PantryViewModel())
    }
}
