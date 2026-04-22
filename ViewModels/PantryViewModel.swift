import Foundation
import Combine

@MainActor
public class PantryViewModel: ObservableObject {
    @Published public private(set) var ingredientsDict: [String: Ingredient] = [:]
    @Published public private(set) var cocktails: [Cocktail] = []
    @Published public var pantryItems: Set<String> = [] {
        didSet { savePantry() }
    }

    private let pantryKey = "CocktailPantry.pantry"
    private let customIngredientsKey = "CocktailPantry.customIngredients"
    private var customIngredients: [String: Ingredient] = [:]

    public enum RecognizedAddResult {
        case added(String)
        case alreadyOwned(String)
        case skipped(String)
    }

    public init() {
        loadDictionary()
        loadCustomIngredients()
        loadCocktails()
        loadPantry()
    }

    private func loadDictionary() {
        if let list: [Ingredient] = DataLoader.loadJSON("Data/ingredients.dictionary.json", type: [Ingredient].self) {
            var dict: [String: Ingredient] = [:]
            for i in list { dict[i.id] = i }
            ingredientsDict = dict
            print("[PantryViewModel] Loaded \(ingredientsDict.count) ingredients")
        } else {
            print("[PantryViewModel] Failed to load ingredients dictionary")
        }
    }

    private func loadCocktails() {
        if let list: [Cocktail] = DataLoader.loadJSON("Data/cocktails.seed.json", type: [Cocktail].self) {
            cocktails = list
            print("[PantryViewModel] Loaded \(cocktails.count) cocktails")
        } else {
            print("[PantryViewModel] Failed to load cocktail seed data")
        }
    }

    private func loadPantry() {
        if let data = UserDefaults.standard.array(forKey: pantryKey) as? [String] {
            pantryItems = Set(data)
        }
    }

    private func loadCustomIngredients() {
        guard let data = UserDefaults.standard.data(forKey: customIngredientsKey) else { return }
        do {
            let list = try JSONDecoder().decode([Ingredient].self, from: data)
            for ingredient in list {
                customIngredients[ingredient.id] = ingredient
                ingredientsDict[ingredient.id] = ingredient
            }
            if !list.isEmpty {
                print("[PantryViewModel] Loaded \(list.count) custom ingredients")
            }
        } catch {
            print("[PantryViewModel] Failed to load custom ingredients: \(error)")
        }
    }

    private func savePantry() {
        UserDefaults.standard.set(Array(pantryItems), forKey: pantryKey)
    }

    private func saveCustomIngredients() {
        do {
            let list = Array(customIngredients.values).sorted { $0.displayName < $1.displayName }
            let data = try JSONEncoder().encode(list)
            UserDefaults.standard.set(data, forKey: customIngredientsKey)
        } catch {
            print("[PantryViewModel] Failed to save custom ingredients: \(error)")
        }
    }

    public func toggleIngredient(_ id: String) {
        if pantryItems.contains(id) {
            pantryItems.remove(id)
        } else {
            pantryItems.insert(id)
        }
    }

    public func addIngredient(_ id: String) {
        if ingredientsDict[id] == nil {
            let createdId = upsertCustomIngredient(displayName: prettifyName(from: id), suggestedId: id, aliases: [id])
            pantryItems.insert(createdId)
            return
        }
        pantryItems.insert(id)
    }

    public func upsertCustomIngredient(displayName: String, suggestedId: String? = nil, aliases: [String] = []) -> String {
        let base = (suggestedId?.isEmpty == false ? suggestedId! : displayName)
        let normalized = normalizeId(base)
        guard !normalized.isEmpty else {
            return base
        }

        if ingredientsDict[normalized] != nil {
            return normalized
        }

        let mergedAliases = Array(Set((aliases + [displayName, normalized])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }))

        let ingredient = Ingredient(
            id: normalized,
            displayName: displayName,
            category: "custom",
            aliases: mergedAliases
        )

        customIngredients[normalized] = ingredient
        ingredientsDict[normalized] = ingredient
        saveCustomIngredients()
        print("[PantryViewModel] Added custom ingredient '\(displayName)' as id '\(normalized)'")
        return normalized
    }

    public func addRecognizedIngredient(_ candidate: Candidate) -> RecognizedAddResult {
        let confidence = max(0, min(1, candidate.confidence))
        var ingredientId = candidate.ingredientId

        if ingredientsDict[ingredientId] == nil {
            // Only create new custom ingredients for reasonably confident AI/OCR matches.
            guard confidence >= 0.55 else {
                return .skipped(candidate.text)
            }
            let cleanedName = prettifyName(from: candidate.text.isEmpty ? candidate.ingredientId : candidate.text)
            ingredientId = upsertCustomIngredient(
                displayName: cleanedName,
                suggestedId: candidate.ingredientId,
                aliases: [candidate.text, candidate.ingredientId]
            )
        }

        if pantryItems.contains(ingredientId) {
            return .alreadyOwned(ingredientId)
        }

        pantryItems.insert(ingredientId)
        return .added(ingredientId)
    }

    public func recommendationResults(missingThreshold: Int = 2) -> [MatchResult] {
        let service = RecommendationService(pantryIngredientIds: pantryItems, cocktails: cocktails)
        return service.matchAll(missingThreshold: missingThreshold)
    }

    public func aggregatedMissing(for selection: [MatchResult]) -> [String: [String]] {
        var map: [String: [String]] = [:]
        for r in selection {
            for m in r.missing {
                map[m, default: []].append(r.cocktail.name)
            }
        }
        return map
    }

    private func normalizeId(_ raw: String) -> String {
        let lowered = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let kept = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
            if scalar == " " || scalar == "_" || scalar == "-" { return "_" }
            return "_"
        }
        let collapsed = String(kept)
            .replacingOccurrences(of: "__+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return collapsed
    }

    private func prettifyName(from raw: String) -> String {
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard !cleaned.isEmpty else { return raw }
        return cleaned.capitalized
    }
}
