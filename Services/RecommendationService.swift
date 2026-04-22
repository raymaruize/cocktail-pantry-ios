import Foundation

public struct MatchResult: Codable, Identifiable {
    public var id: String { cocktail.id }
    public let cocktail: Cocktail
    public let missing: [String]
    public var canMake: Bool { missing.isEmpty }
}

public class RecommendationService {
    private let cocktails: [Cocktail]
    private let pantrySet: Set<String>
    private let ingredients: [String: Ingredient]

    public init(pantryIngredientIds: Set<String>, cocktails: [Cocktail], ingredients: [String: Ingredient] = [:]) {
        self.pantrySet = pantryIngredientIds
        self.cocktails = cocktails
        self.ingredients = ingredients
    }

    public func matchAll(missingThreshold: Int = 2) -> [MatchResult] {
        let effectivePantry = expandedPantrySet()
        var results: [MatchResult] = []
        for c in cocktails {
            let required = c.ingredients.filter { ($0.optional ?? false) == false }.map { $0.ingredientId }
            let missing = required.filter { !effectivePantry.contains($0) }
            if missing.count <= missingThreshold {
                results.append(MatchResult(cocktail: c, missing: missing))
            }
        }
        return results.sorted { (a, b) -> Bool in
            if a.missing.count != b.missing.count {
                return a.missing.count < b.missing.count
            }
            let ap = a.cocktail.popularityScore ?? 0
            let bp = b.cocktail.popularityScore ?? 0
            return ap > bp
        }
    }

    private func expandedPantrySet() -> Set<String> {
        var expanded = pantrySet
        for id in pantrySet {
            guard let ingredient = ingredients[id], let satisfies = ingredient.satisfies else { continue }
            for canonicalId in satisfies {
                expanded.insert(canonicalId)
            }
        }
        return expanded
    }
}
