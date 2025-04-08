//
//  ChatMessage.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id = UUID()
    var role: String
    var content: String
    var timestamp: Date
    var modelName: String

    init(role: String, content: String, modelName: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.modelName = modelName
    }
}

// API Request/Response Models
struct ChatRequest: Codable {
    let model: String
    let messages: [Message]
    let stream: Bool
    let options: [String: String]?

    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct ChatResponse: Codable {
    let model: String
    let createdAt: String
    let message: Message
    let done: Bool
    let totalDuration: Int64?

    struct Message: Codable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
        case totalDuration = "total_duration"
    }
}

struct GenerateRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: [String: String]?
}

struct GenerateResponse: Codable {
    let model: String
    let createdAt: String
    let response: String
    let done: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
    }
}
