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

    public init(pantryIngredientIds: Set<String>, cocktails: [Cocktail]) {
        self.pantrySet = pantryIngredientIds
        self.cocktails = cocktails
    }

    public func matchAll(missingThreshold: Int = 2) -> [MatchResult] {
        var results: [MatchResult] = []
        for c in cocktails {
            let required = c.ingredients.filter { ($0.optional ?? false) == false }.map { $0.ingredientId }
            let missing = required.filter { !pantrySet.contains($0) }
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
}
