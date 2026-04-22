import Foundation

public struct Candidate {
    public let text: String
    public let ingredientId: String
    public let confidence: Double
    public let reason: String
}

public class NormalizationService {
    private let dict: [String: Ingredient]

    public init(dictionary: [String: Ingredient]) {
        self.dict = dictionary
    }

    private func normalize(_ s: String) -> String {
        return s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .components(separatedBy: CharacterSet.punctuationCharacters).joined()
    }

    public func candidates(for snippets: [String], maxCandidates: Int = 3) -> [Candidate] {
        var scores: [Candidate] = []
        let aliasMap: [String: String] = buildAliasMap()

        for raw in snippets {
            let s = normalize(raw)
            // exact alias match
            if let id = aliasMap[s] {
                scores.append(Candidate(text: raw, ingredientId: id, confidence: 0.95, reason: "alias exact match"))
                continue
            }

            // substring match
            for (alias, id) in aliasMap {
                if alias.contains(s) || s.contains(alias) {
                    scores.append(Candidate(text: raw, ingredientId: id, confidence: 0.6, reason: "substring match with alias '\(alias)'"))
                }
            }
        }

        // Deduplicate by ingredientId keeping highest confidence
        var best: [String: Candidate] = [:]
        for c in scores {
            if let prev = best[c.ingredientId] {
                if c.confidence > prev.confidence { best[c.ingredientId] = c }
            } else { best[c.ingredientId] = c }
        }

        return Array(best.values).sorted { $0.confidence > $1.confidence }.prefix(maxCandidates).map { $0 }
    }

    private func buildAliasMap() -> [String: String] {
        var map: [String: String] = [:]
        for (_, ing) in dict {
            for a in ing.aliases {
                let key = normalize(a)
                map[key] = ing.id
            }
            // also map displayName
            map[normalize(ing.displayName)] = ing.id
        }
        return map
    }
}
