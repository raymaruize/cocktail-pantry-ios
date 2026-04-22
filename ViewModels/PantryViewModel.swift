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

    public init() {
        loadDictionary()
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

    private func savePantry() {
        UserDefaults.standard.set(Array(pantryItems), forKey: pantryKey)
    }

    public func toggleIngredient(_ id: String) {
        if pantryItems.contains(id) {
            pantryItems.remove(id)
        } else {
            pantryItems.insert(id)
        }
    }

    public func addIngredient(_ id: String) {
        pantryItems.insert(id)
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
}
