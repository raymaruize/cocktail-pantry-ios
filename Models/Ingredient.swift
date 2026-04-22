import Foundation

public struct Ingredient: Codable, Identifiable, Hashable {
    public let id: String
    public let displayName: String
    public let category: String
    public let aliases: [String]
    public let satisfies: [String]?
}
