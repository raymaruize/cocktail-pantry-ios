import Foundation
import Security

public enum AIServiceError: LocalizedError {
    case notOptedIn
    case missingAPIKey
    case invalidResponse
    case parseFailed

    public var errorDescription: String? {
        switch self {
        case .notOptedIn: return "OpenAI integration is not enabled in settings."
        case .missingAPIKey: return "Missing OpenAI API key."
        case .invalidResponse: return "OpenAI returned an unexpected response."
        case .parseFailed: return "Unable to parse model output."
        }
    }
}

/// Minimal AIService stub for OpenAI integration. This file provides an opt-in hook and a secure key holder.
public class AIService {
    public static let shared = AIService()

    private init() {}

    public func isOptedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: "AIService.optIn")
    }

    public func setOptIn(_ flag: Bool) {
        UserDefaults.standard.set(flag, forKey: "AIService.optIn")
    }

    public func storeAPIKey(_ key: String) {
        // Simple Keychain wrapper; production code should use robust Keychain handling.
        let service = "CocktailPantry.OpenAI"
        let account = "user"
        if let data = key.data(using: .utf8) {
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                        kSecAttrService as String: service,
                                        kSecAttrAccount as String: account]
            SecItemDelete(query as CFDictionary)
            let add: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                      kSecAttrService as String: service,
                                      kSecAttrAccount as String: account,
                                      kSecValueData as String: data]
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    public func getAPIKey() -> String? {
        let service = "CocktailPantry.OpenAI"
        let account = "user"
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let key = String(data: data, encoding: .utf8) else {
            print("[AIService] Keychain retrieval failed with status \(status)")
            return nil
        }
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            print("[AIService] API key is empty after retrieval")
            return nil
        }
        print("[AIService] API key retrieved successfully (length: \(trimmed.count))")
        return trimmed
    }

    public func suggestIngredientCandidates(
        from snippets: [String],
        dictionary: [String: Ingredient],
        completion: @escaping (Result<[Candidate], Error>) -> Void
    ) {
        guard isOptedIn() else {
            print("[AIService] AI not opted in")
            completion(.failure(AIServiceError.notOptedIn))
            return
        }
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            print("[AIService] Missing or empty API key")
            completion(.failure(AIServiceError.missingAPIKey))
            return
        }

        var workingDictionary = dictionary
        if workingDictionary.isEmpty,
           let list: [Ingredient] = DataLoader.loadJSON("Data/ingredients.dictionary.json", type: [Ingredient].self) {
            var recovered: [String: Ingredient] = [:]
            for ingredient in list {
                recovered[ingredient.id] = ingredient
            }
            workingDictionary = recovered
            print("[AIService] Recovered dictionary from bundle with \(workingDictionary.count) ingredients")
        }

        guard !workingDictionary.isEmpty else {
            print("[AIService] Ingredient dictionary is empty; cannot map AI output")
            completion(.failure(NSError(domain: "AIService", code: 1001, userInfo: ["message": "Ingredient dictionary failed to load."])))
            return
        }

        // Build a mapping of ingredient names to IDs for OpenAI to use
        let ingredientList = workingDictionary.values
            .sorted { $0.displayName < $1.displayName }
            .map { "\($0.displayName) (ID: \($0.id))" }
            .joined(separator: "\n")
        
        let payloadText = snippets.joined(separator: " | ")
        
        print("[AIService] Requesting suggestions for: \(payloadText)")
        print("[AIService] Dictionary has \(workingDictionary.count) ingredients")

        let system = """
        You are an expert at matching beverage names from OCR text to a list of known ingredients.
        
        Given OCR text snippets, find the best matches from the provided ingredient list.
        Return STRICT JSON ONLY, as an array of matches.
        
        For each match, return:
        {"ingredientId":"ID_STRING","confidence":0.95,"reason":"why this is a match","text":"original_text"}
        
        Rules:
        - Confidence is 0.0 to 1.0
        - Match brand names, spirit types, mixers, juices
        - Extract the ingredient ID from the list exactly as shown
        - Return empty array [] if no good matches found
        - Do not return any text besides the JSON array
        
        Available ingredients:
        \(ingredientList)
        """

        let user = "Find matching ingredients for: \(payloadText)"

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "temperature": 0,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("[AIService] Request body serialization failed: \(error)")
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("[AIService] Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[AIService] Response status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? "(no body)"
                    print("[AIService] ❌ ERROR Response: \(body)")
                    // Try to extract error message from OpenAI response
                    if let data = data {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let error = json["error"] as? [String: Any],
                               let message = error["message"] as? String {
                                print("[AIService] OpenAI error message: \(message)")
                                completion(.failure(NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: ["message": message])))
                                return
                            }
                        } catch {}
                    }
                    completion(.failure(NSError(domain: "OpenAI", code: httpResponse.statusCode)))
                    return
                }
            }
            
            guard let data else {
                print("[AIService] No data received")
                completion(.failure(AIServiceError.invalidResponse))
                return
            }

            do {
                let chat = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                guard let content = chat.choices.first?.message.content else {
                    print("[AIService] No content in response")
                    completion(.failure(AIServiceError.invalidResponse))
                    return
                }
                
                print("[AIService] Raw content: \(content)")

                let clean = Self.extractJSONArray(from: content)
                print("[AIService] Extracted JSON: \(clean)")
                
                let parsed = try JSONDecoder().decode([AICandidatePayload].self, from: Data(clean.utf8))
                print("[AIService] Parsed \(parsed.count) candidates")
                
                let candidates = parsed.compactMap { item -> Candidate? in
                    // Try exact match first
                    if workingDictionary[item.ingredientId] != nil {
                        return Candidate(
                            text: item.text,
                            ingredientId: item.ingredientId,
                            confidence: max(0, min(1, item.confidence)),
                            reason: "AI: \(item.reason)"
                        )
                    }
                    
                    // Try case-insensitive match
                    let normalized = item.ingredientId.lowercased().replacingOccurrences(of: " ", with: "_")
                    if workingDictionary[normalized] != nil {
                        return Candidate(
                            text: item.text,
                            ingredientId: normalized,
                            confidence: max(0, min(1, item.confidence)),
                            reason: "AI: \(item.reason)"
                        )
                    }
                    
                    // Try partial match against known IDs
                    for (realId, _) in workingDictionary {
                        if realId.lowercased().contains(normalized) || normalized.contains(realId.lowercased()) {
                            print("[AIService] Fuzzy matched '\(item.ingredientId)' to '\(realId)'")
                            return Candidate(
                                text: item.text,
                                ingredientId: realId,
                                confidence: max(0, min(1, item.confidence * 0.9)), // Reduce confidence slightly for fuzzy match
                                reason: "AI: \(item.reason) [matched to \(realId)]"
                            )
                        }
                    }
                    
                    print("[AIService] Skipping unknown ingredient: \(item.ingredientId)")
                    return nil
                }
                print("[AIService] Returning \(candidates.count) valid candidates")
                completion(.success(candidates))
            } catch {
                print("[AIService] Parse error: \(error)")
                completion(.failure(AIServiceError.parseFailed))
            }
        }.resume()
    }

    private static func extractJSONArray(from text: String) -> String {
        if let start = text.firstIndex(of: "["), let end = text.lastIndex(of: "]"), start <= end {
            return String(text[start...end])
        }
        return text
    }
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct AICandidatePayload: Decodable {
    let ingredientId: String
    let confidence: Double
    let reason: String
    let text: String
}
