import Foundation

public struct Cocktail: Codable, Identifiable {
    public let id: String
    public let name: String
    public let ingredients: [CocktailIngredient]
    public let method: String
    public let ice: String?
    public let glassware: String?
    public let garnish: [String]?
    public let flavorTags: [String]?
    public let popularityScore: Int?
}

public struct CocktailIngredient: Codable {
    public let ingredientId: String
    public let amount: String?
    public let optional: Bool?
}
