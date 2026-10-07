//
//  OpenAIService.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation

final class OpenAIService {
    static let shared = OpenAIService()
    
    private let apiKey = "API_KEY"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    func improveText(_ text: String, context: String = "allgemein") async -> String? {
        return await sendRequest(
            systemPrompt: "Du bist ein hilfreicher Assistent, der Text verbessert: Mach ihn professioneller, korrigiere Grammatik und mache ihn klarer. Kontext: \(context).",
            userPrompt: "Verbessere diesen Text: \(text)",
            maxTokens: 500
        )
    }
    
    func summarizeText(_ text: String) async -> String? {
        return await sendRequest(
            systemPrompt: "Du bist ein hilfreicher Assistent, der Texte prägnant zusammenfasst. Fasse den folgenden Text in 1-2 Sätzen zusammen, behalte die Kernaussage bei und mache ihn klar und verständlich.",
            userPrompt: "Fasse diesen Text zusammen: \(text)",
            maxTokens: 500
        )
    }
    
    func optimizeServiceDescription(_ description: String) async -> String? {
        return await sendRequest(
            systemPrompt: "Du bist ein Marketing-Experte, der Service-Beschreibungen optimiert. Mache sie ansprechender, professioneller und überzeugender für potenzielle Kunden. Behalte alle wichtigen Informationen bei.",
            userPrompt: "Optimiere diese Service-Beschreibung: \(description)",
            maxTokens: 500
        )
    }
    
    func enhanceProjectDescription(_ description: String) async -> String? {
        return await sendRequest(
            systemPrompt: "Du hilfst dabei, Projekt-Beschreibungen zu verbessern. Mache sie detaillierter, strukturierter und klarer, damit Dienstleister besser verstehen, was gewünscht wird.",
            userPrompt: "Verbessere diese Projekt-Beschreibung: \(description)",
            maxTokens: 500
        )
    }
    
    func generateChatResponse(_ message: String, context: String = "") async -> String? {
        let contextPrompt = context.isEmpty ? "" : "Kontext: \(context). "
        return await sendRequest(
            systemPrompt: "\(contextPrompt)Du bist ein hilfreicher Assistent für professionelle Kommunikation. Antworte höflich, professionell und hilfreich.",
            userPrompt: message,
            maxTokens: 500
        )
    }
    
    private func sendRequest(
        systemPrompt: String,
        userPrompt: String,
        maxTokens: Int = 300,
        temperature: Double = 0.7
    ) async -> String? {
        guard let url = URL(string: baseURL) else {
            return nil
        }
        
        let requestBody = ChatCompletionRequest(
            model: "gpt-4.1-nano",
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: userPrompt)
            ],
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        guard let httpBody = try? JSONEncoder().encode(requestBody) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody
        request.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    return nil
                }
            }
            
            let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            return chatResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            return nil
        }
    }
}

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Codable {
    let choices: [ChatChoice]
}

private struct ChatChoice: Codable {
    let message: ChatMessage
}

extension OpenAIService {
    
    func improveText(_ text: String, context: String = "allgemein", completion: @escaping (String?) -> Void) {
        Task {
            let result = await improveText(text, context: context)
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    func summarizeText(_ text: String, completion: @escaping (String?) -> Void) {
        Task {
            let result = await summarizeText(text)
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    func canImproveText(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.count >= 10 && trimmedText.count <= 2000
    }
    
    func estimateTokenCount(for text: String) -> Int {
        return text.count / 4
    }
    
    var isConfigured: Bool {
        return !apiKey.isEmpty && apiKey != "API_KEY"
    }
}

enum OpenAIServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case invalidResponse
    case textTooLong
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "OpenAI API-Schlüssel ist ungültig"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .invalidResponse:
            return "Ungültige Antwort von OpenAI"
        case .textTooLong:
            return "Text ist zu lang für die Verarbeitung"
        case .rateLimitExceeded:
            return "Rate-Limit erreicht. Bitte versuchen Sie es später erneut."
        }
    }
}

extension OpenAIService {
    private static let usageKey = "openai_usage_count"
    private static let lastResetKey = "openai_usage_reset"
    
    private func incrementUsageCount() {
        let currentCount = UserDefaults.standard.integer(forKey: Self.usageKey)
        UserDefaults.standard.set(currentCount + 1, forKey: Self.usageKey)
    }
    
    func getCurrentUsageCount() -> Int {
        return UserDefaults.standard.integer(forKey: Self.usageKey)
    }
    
    func resetUsageCount() {
        UserDefaults.standard.set(0, forKey: Self.usageKey)
        UserDefaults.standard.set(Date(), forKey: Self.lastResetKey)
    }
}
