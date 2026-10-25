import Foundation

struct GeminiService {
    enum ServiceError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case api(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Спочатку додай Gemini API key у налаштуваннях."
            case .invalidResponse:
                return "Не вдалося прочитати відповідь Gemini."
            case .api(let message):
                return message
            }
        }
    }

    func reply(to prompt: String, history: [ChatMessage]) async throws -> String {
        let apiKey = KeychainStore.read().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else { throw ServiceError.missingAPIKey }

        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var contents: [[String: Any]] = []
        for message in history.suffix(12) where message.role != .system {
            contents.append([
                "role": message.role == .assistant ? "model" : "user",
                "parts": [["text": message.text]]
            ])
        }
        contents.append(["role": "user", "parts": [["text": prompt]]])

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [[
                    "text": "Ти J.A.R.V.I.S. — персональний ШІ-помічник, створений Flomber. Відповідай українською, якщо користувач не просить іншої мови. Будь природним, точним і чесним. Не стверджуй, що виконав дії на iPad, якщо не маєш відповідного інструмента."
                ]]
            ],
            "contents": contents,
            "generationConfig": ["temperature": 0.7, "maxOutputTokens": 2048]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let decoded = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let errorObject = decoded?["error"] as? [String: Any]
            throw ServiceError.api(errorObject?["message"] as? String ?? "Gemini API повернув HTTP \(http.statusCode).")
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]]
        else { throw ServiceError.invalidResponse }

        let text = parts.compactMap { $0["text"] as? String }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ServiceError.invalidResponse }
        return text
    }
}

enum ChatRole {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let text: String
}
