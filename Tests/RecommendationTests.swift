import XCTest
@testable import CocktailPantry

final class RecommendationTests: XCTestCase {
    func testMargaritaCanMake() throws {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let path = URL(fileURLWithPath: cwd).appendingPathComponent("Data/cocktails.seed.json")
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        let cocktails = try decoder.decode([Cocktail].self, from: data)

        let pantry: Set<String> = ["tequila", "triple_sec", "lime_juice"]
        let svc = RecommendationService(pantryIngredientIds: pantry, cocktails: cocktails)
        let results = svc.matchAll(missingThreshold: 0)
        XCTAssertTrue(results.contains { $0.cocktail.id == "margarita" && $0.canMake })
    }
}
