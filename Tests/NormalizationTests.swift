import XCTest
@testable import CocktailPantry

final class NormalizationTests: XCTestCase {
    func testAliasExactMatch() throws {
        // Load dictionary
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let path = URL(fileURLWithPath: cwd).appendingPathComponent("Data/ingredients.dictionary.json")
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        let list = try decoder.decode([Ingredient].self, from: data)
        var dict: [String: Ingredient] = [:]
        for i in list { dict[i.id] = i }
        let svc = NormalizationService(dictionary: dict)
        let cands = svc.candidates(for: ["Cointreau"]) // alias for triple_sec
        XCTAssertTrue(cands.contains { $0.ingredientId == "triple_sec" })
    }
}
