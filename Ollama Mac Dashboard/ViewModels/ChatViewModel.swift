//
//  ChatViewModel.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import Foundation
import SwiftData
import Combine

class ChatViewModel: ObservableObject {
    private let ollamaService = OllamaService()
    private var modelContext: ModelContext?
    
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedModel: OllamaModel?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func loadMessages(for modelName: String) {
        guard let modelContext = modelContext else { return }
        
        let predicate = #Predicate<ChatMessage> { message in
            message.modelName == modelName
        }
        
        let descriptor = FetchDescriptor<ChatMessage>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        
        do {
            messages = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
        }
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let selectedModel = selectedModel else {
            return
        }
        
        let userMessage = ChatMessage(role: "user", content: inputMessage, modelName: selectedModel.name)
        
        // Add user message to the list
        messages.append(userMessage)
        
        // Save to SwiftData
        modelContext?.insert(userMessage)
        
        // Clear input field
        let userPrompt = inputMessage
        inputMessage = ""
        
        // Set loading state
        isLoading = true
        errorMessage = nil
        
        // Prepare API request
        let apiMessages = messages.map { ChatRequest.Message(role: $0.role, content: $0.content) }
        
        Task {
            do {
                let response = try await ollamaService.chat(
                    model: selectedModel.name,
                    messages: apiMessages
                )
                
                await MainActor.run {
                    // Create and add assistant message
                    let assistantMessage = ChatMessage(
                        role: "assistant",
                        content: response.message.content,
                        modelName: selectedModel.name
                    )
                    
                    self.messages.append(assistantMessage)
                    
                    // Save to SwiftData
                    self.modelContext?.insert(assistantMessage)
                    
                    // Update state
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to get response: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func clearChat() {
        guard let modelContext = modelContext, let selectedModel = selectedModel else { return }
        
        // Delete all messages for this model
        for message in messages {
            modelContext.delete(message)
        }
        
        // Clear the messages array
        messages = []
    }
}
