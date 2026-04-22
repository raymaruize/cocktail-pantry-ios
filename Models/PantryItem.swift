import Foundation

public struct PantryItem: Codable, Identifiable, Hashable {
    public let id: String
    public var isAvailable: Bool

    public init(id: String, isAvailable: Bool = true) {
        self.id = id
        self.isAvailable = isAvailable
    }
}
