package com.findurdevkotlin.data.repository

import com.theokanning.openai.completion.chat.ChatCompletionRequest
import com.theokanning.openai.completion.chat.ChatMessage
import com.theokanning.openai.service.OpenAiService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.Duration

class OpenAIService {
    private val apiKey = "API_KEY"
    private val service = OpenAiService(apiKey, Duration.ofSeconds(30))

    suspend fun improveText(text: String, context: String = "allgemein"): String? = withContext(Dispatchers.IO) {
        try {
            val messages = listOf(
                ChatMessage("system", "Du bist ein hilfreicher Assistent, der Text verbessert: Mach ihn professioneller, korrigiere Grammatik und mache ihn klarer. Kontext: $context."),
                ChatMessage("user", "Verbessere diesen Text: $text")
            )
            val request = ChatCompletionRequest.builder()
                .model("gpt-4.1-nano")
                .messages(messages)
                .temperature(0.7)
                .maxTokens(500)
                .build()
            val response = service.createChatCompletion(request)
            response.choices.firstOrNull()?.message?.content?.trim()
        } catch (_: Exception) {
            null
        }
    }

    suspend fun summarizeText(text: String): String? = withContext(Dispatchers.IO) {
        try {
            val messages = listOf(
                ChatMessage("system", "Du bist ein hilfreicher Assistent, der Texte prägnant zusammenfasst. Fasse den folgenden Text in 1-2 Sätzen zusammen, behalte die Kernaussage bei und mache ihn klar und verständlich."),
                ChatMessage("user", "Fasse diesen Text zusammen: $text")
            )
            val request = ChatCompletionRequest.builder()
                .model("gpt-4.1-nano")
                .messages(messages)
                .temperature(0.7)
                .maxTokens(100)
                .build()
            val response = service.createChatCompletion(request)
            response.choices.firstOrNull()?.message?.content?.trim()
        } catch (_: Exception) {
            null
        }
    }
}