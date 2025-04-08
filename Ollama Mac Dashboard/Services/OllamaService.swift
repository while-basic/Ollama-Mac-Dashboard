//
//  OllamaService.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import Foundation
import Combine

enum OllamaError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case unknown
}

class OllamaService: ObservableObject {
    private let baseURL = "http://127.0.0.1:11434/api"

    // Add a shared instance for easy access
    static let shared = OllamaService()
    private var cancellables = Set<AnyCancellable>()

    @Published var isLoading = false
    @Published var error: OllamaError?

    // MARK: - Connectivity

    func checkOllamaConnection() async -> Bool {
        do {
            let url = URL(string: "\(baseURL)/tags")!
            print("Checking Ollama connection at: \(url)")

            // Create a custom URL session configuration
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 5 // 5 second timeout
            let session = URLSession(configuration: config)

            let (_, response) = try await session.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("Ollama connection check status code: \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200
            }

            return false
        } catch let error as NSError {
            print("Ollama connection check failed: \(error.localizedDescription)")
            print("Error domain: \(error.domain), code: \(error.code)")
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("Underlying error: \(underlyingError.localizedDescription)")
                print("Underlying domain: \(underlyingError.domain), code: \(underlyingError.code)")
            }
            return false
        }
    }

    // MARK: - Models

    func listModels() async throws -> [OllamaModel] {
        let url = URL(string: "\(baseURL)/tags")!

        print("Fetching models from: \(url)")

        // Create a custom URL session configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10 // 10 second timeout
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(from: url)

            // Print response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")

                if httpResponse.statusCode != 200 {
                    throw OllamaError.apiError("Server returned status code \(httpResponse.statusCode)")
                }
            }

            // Print raw data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }

            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZZZZZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            let modelList = try decoder.decode(OllamaModelList.self, from: data)
            print("Decoded \(modelList.models.count) models")
            return modelList.models
        } catch let error as NSError {
            print("Error fetching models: \(error.localizedDescription)")
            print("Error domain: \(error.domain), code: \(error.code)")
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("Underlying error: \(underlyingError.localizedDescription)")
                print("Underlying domain: \(underlyingError.domain), code: \(underlyingError.code)")
            }
            throw error
        }
    }

    func listRunningModels() async throws -> [RunningModel] {
        let url = URL(string: "\(baseURL)/ps")!

        print("Fetching running models from: \(url)")

        // Create a custom URL session configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10 // 10 second timeout
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(from: url)

            // Print response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")

                if httpResponse.statusCode != 200 {
                    throw OllamaError.apiError("Server returned status code \(httpResponse.statusCode)")
                }
            }

            // Print raw data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }

            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZZZZZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            let modelList = try decoder.decode(RunningModelList.self, from: data)
            print("Decoded \(modelList.models.count) running models")
            return modelList.models
        } catch let error as NSError {
            print("Error fetching running models: \(error.localizedDescription)")
            print("Error domain: \(error.domain), code: \(error.code)")
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("Underlying error: \(underlyingError.localizedDescription)")
                print("Underlying domain: \(underlyingError.domain), code: \(underlyingError.code)")
            }
            throw OllamaError.decodingError(error)
        }
    }

    func pullModel(name: String) -> AnyPublisher<String, OllamaError> {
        let url = URL(string: "\(baseURL)/pull")!

        let body: [String: Any] = [
            "model": name,
            "stream": true
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw OllamaError.apiError("Failed to pull model")
                }
                return data
            }
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .map { $0["status"] ?? "Unknown status" }
            .mapError { error -> OllamaError in
                if let error = error as? OllamaError {
                    return error
                }
                return OllamaError.networkError(error)
            }
            .eraseToAnyPublisher()
    }

    func deleteModel(name: String) async throws {
        let url = URL(string: "\(baseURL)/delete")!

        let body: [String: Any] = [
            "model": name
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.apiError("Failed to delete model")
        }
    }

    // MARK: - Chat

    func chat(model: String, messages: [ChatRequest.Message], options: [String: String]? = nil) async throws -> ChatResponse {
        let url = URL(string: "\(baseURL)/chat")!

        var body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "stream": false
        ]

        // Add options if provided
        if let options = options, !options.isEmpty {
            body["options"] = options
        } else {
            body["options"] = [String: String]()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.apiError("Failed to chat with model")
        }

        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }

    func generate(model: String, prompt: String) async throws -> GenerateResponse {
        let url = URL(string: "\(baseURL)/generate")!

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": [String: String]()
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.apiError("Failed to generate text")
        }

        return try JSONDecoder().decode(GenerateResponse.self, from: data)
    }

    // MARK: - Model Management

    func loadModel(name: String) async throws {
        let url = URL(string: "\(baseURL)/generate")!

        let body: [String: Any] = [
            "model": name
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.apiError("Failed to load model")
        }
    }

    func unloadModel(name: String) async throws {
        let url = URL(string: "\(baseURL)/generate")!

        let body: [String: Any] = [
            "model": name,
            "keep_alive": 0
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.apiError("Failed to unload model")
        }
    }
}
