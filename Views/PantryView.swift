import SwiftUI
import UIKit

struct PantryView: View {
    @ObservedObject var viewModel: PantryViewModel
    @State private var showingOCRSheet = false
    @State private var showingSourceDialog = false
    @State private var showingCameraPicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var isProcessingOCR = false
    @State private var aiEnabled = false
    @State private var ocrText = ""
    @State private var candidates: [Candidate] = []
    @State private var statusMessage: String? = nil
    @State private var showingStatusAlert = false
    @State private var searchText = ""
    @State private var showingManualSearch = false

    private let ocrService = OCRService()
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private var filteredIngredients: [Ingredient] {
        let query = searchText.lowercased()
        guard !query.isEmpty else {
            return Array(viewModel.ingredientsDict.values).sorted(by: { $0.displayName < $1.displayName })
        }
        return Array(viewModel.ingredientsDict.values)
            .filter { $0.displayName.lowercased().contains(query) }
            .sorted(by: { $0.displayName < $1.displayName })
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color.blue.opacity(0.22), Color.purple.opacity(0.12), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroHeader

                        Text("Ingredients")
                            .font(.title3.weight(.semibold))
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(viewModel.ingredientsDict.values).sorted(by: { $0.displayName < $1.displayName })) { ing in
                                ingredientTile(ing)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 110)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Pantry")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showingManualSearch = true }) {
                            Image(systemName: "magnifyingglass")
                        }
                        Button(action: { showingSourceDialog = true }) {
                            Image(systemName: "camera.viewfinder")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Image(systemName: "checklist")
                    Text("\(viewModel.pantryItems.count) items in pantry")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .confirmationDialog("Add from", isPresented: $showingSourceDialog) {
                Button("Camera") { showingCameraPicker = true }
                Button("Photo Library") { showingPhotoPicker = true }
                Button("Manual OCR Text") { showingOCRSheet = true }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showingOCRSheet) {
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Paste OCR text or type label text to map to ingredients:")
                                .font(.subheadline)
                            TextEditor(text: $ocrText)
                                .frame(height: 100)
                                .border(Color.secondary)
                                .cornerRadius(4)

                            HStack(spacing: 8) {
                                Button("Suggest + Add") {
                                    runSuggestionsFromText(autoAdd: true)
                                }
                                .disabled(ocrText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessingOCR)

                                Toggle("Use OpenAI", isOn: $aiEnabled)
                            }

                            if !candidates.isEmpty {
                                Button("Add All to Owned") {
                                    addCandidatesToPantry(candidates)
                                }
                                .font(.subheadline.weight(.semibold))
                            }

                            if isProcessingOCR {
                                VStack(spacing: 8) {
                                    ProgressView()
                                    Text("Analyzing...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(20)
                            }

                            if let statusMsg = statusMessage {
                                Text(statusMsg)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }

                            if !candidates.isEmpty {
                                Text("Suggestions (\(candidates.count))")
                                    .font(.subheadline.weight(.semibold))

                                VStack(spacing: 8) {
                                    ForEach(candidates, id: \.ingredientId) { c in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(viewModel.ingredientsDict[c.ingredientId]?.displayName ?? c.ingredientId)
                                                    .font(.headline)
                                                Text(String(format: "Conf: %.0f%% — %@", c.confidence * 100, c.reason))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Button(action: { viewModel.toggleIngredient(c.ingredientId) }) {
                                                Image(systemName: viewModel.pantryItems.contains(c.ingredientId) ? "checkmark.circle.fill" : "plus.circle")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color(.secondarySystemBackground))
                                        )
                                    }
                                }
                            } else if !isProcessingOCR && !ocrText.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text("No suggestions found. Try adding more text or disable OpenAI to use local matching.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(12)
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .navigationTitle("OCR Suggest")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showingOCRSheet = false }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCameraPicker) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
                        .ignoresSafeArea()
                }
            }
            .fullScreenCover(isPresented: $showingPhotoPicker) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
                        .ignoresSafeArea()
                }
            }
            .onChange(of: selectedImage) { image in
                guard let image else { return }
                processImage(image)
                selectedImage = nil
            }
            .sheet(isPresented: $showingManualSearch) {
                NavigationView {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search ingredients...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        if filteredIngredients.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("No ingredients found")
                                    .font(.headline)
                                Text("Try a different search term")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxHeight: .infinity)
                            .padding(32)
                        } else {
                            List {
                                ForEach(filteredIngredients, id: \.id) { ing in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(ing.displayName)
                                                .font(.headline)
                                            Text(ing.category.capitalized)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button(action: {
                                            viewModel.toggleIngredient(ing.id)
                                        }) {
                                            Image(systemName: viewModel.pantryItems.contains(ing.id) ? "checkmark.circle.fill" : "plus.circle")
                                                .foregroundColor(viewModel.pantryItems.contains(ing.id) ? .green : .blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Search Ingredients")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingManualSearch = false
                                searchText = ""
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $showingStatusAlert) {
                Alert(title: Text("Pantry"), message: Text(statusMessage ?? ""), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build your bar")
                .font(.title2.weight(.bold))
            Text("Scan bottles or add ingredients to unlock cocktails instantly.")
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                statPill(title: "Owned", value: "\(viewModel.pantryItems.count)", system: "checkmark.circle.fill", tint: .green)
                statPill(title: "Catalog", value: "\(viewModel.ingredientsDict.count)", system: "shippingbox.fill", tint: .blue)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func statPill(title: String, value: String, system: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: system)
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.subheadline.weight(.bold))
                Text(title).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.tertiarySystemBackground)))
    }

    private func ingredientTile(_ ing: Ingredient) -> some View {
        Button {
            viewModel.toggleIngredient(ing.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: viewModel.pantryItems.contains(ing.id) ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundColor(viewModel.pantryItems.contains(ing.id) ? .green : .blue)
                    Spacer()
                    Text(ing.category.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.tertiarySystemBackground)))
                        .foregroundColor(.secondary)
                }

                Text(ing.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func processImage(_ image: UIImage) {
        isProcessingOCR = true
        ocrService.recognizeText(from: image) { snippets in
            DispatchQueue.main.async {
                ocrText = snippets.joined(separator: "\n")
                showingOCRSheet = true
                isProcessingOCR = false
                runSuggestionsFromText(autoAdd: true)
            }
        }
    }

    private func runSuggestionsFromText(autoAdd: Bool = true) {
        statusMessage = nil
        let text = ocrText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            statusMessage = "Please enter some text first."
            return
        }
        
        let svc = NormalizationService(dictionary: viewModel.ingredientsDict)
        let parts = text.split(whereSeparator: { $0.isNewline || $0 == "," }).map { String($0) }
        var local = svc.candidates(for: parts)

        guard aiEnabled else {
            isProcessingOCR = false
            candidates = local.isEmpty ? [] : local
            if local.isEmpty {
                statusMessage = "No local matches found. Try enabling OpenAI or add more text."
            } else if autoAdd {
                addCandidatesToPantry(candidates)
            }
            return
        }

        isProcessingOCR = true
        AIService.shared.suggestIngredientCandidates(from: parts, dictionary: viewModel.ingredientsDict) { result in
            DispatchQueue.main.async {
                self.isProcessingOCR = false
                switch result {
                case .success(let ai):
                    var best: [String: Candidate] = [:]
                    let combined = local + ai
                    for c in combined {
                        if let prev = best[c.ingredientId], prev.confidence >= c.confidence { continue }
                        best[c.ingredientId] = c
                    }
                    self.candidates = Array(best.values).sorted { $0.confidence > $1.confidence }.prefix(8).map { $0 }
                    if self.candidates.isEmpty {
                        self.statusMessage = "No matches found from OpenAI or local dictionary."
                    } else if autoAdd {
                        self.addCandidatesToPantry(self.candidates)
                    }
                case .failure(let error):
                    self.candidates = local
                    if autoAdd && !local.isEmpty {
                        self.addCandidatesToPantry(local)
                    }
                    let errorMsg = (error as NSError).userInfo["message"] as? String ?? error.localizedDescription
                    self.statusMessage = "OpenAI error: \(errorMsg)"
                    print("[OCR] AI error: \(error)")
                }
            }
        }
    }

    private func addCandidatesToPantry(_ found: [Candidate]) {
        var added = 0
        for id in Set(found.map(\.ingredientId)) {
            if !viewModel.pantryItems.contains(id) {
                viewModel.addIngredient(id)
                added += 1
            }
        }

        if added > 0 {
            statusMessage = "Added \(added) ingredient(s) to Owned pantry."
        } else if !found.isEmpty {
            statusMessage = "These ingredients are already in your Owned pantry."
        }
    }
}

struct PantryView_Previews: PreviewProvider {
    static var previews: some View {
        PantryView(viewModel: PantryViewModel())
    }
}
