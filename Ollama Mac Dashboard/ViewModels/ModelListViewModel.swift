//
//  ModelListViewModel.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import Foundation
import Combine

class ModelListViewModel: ObservableObject {
    private let ollamaService = OllamaService.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var models: [OllamaModel] = []
    @Published var runningModels: [RunningModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pullProgress: [String: String] = [:]
    @Published var ollamaIsRunning = false

    func checkOllamaConnection() {
        Task {
            let isRunning = await ollamaService.checkOllamaConnection()
            await MainActor.run {
                self.ollamaIsRunning = isRunning
                if isRunning {
                    self.loadModels()
                } else {
                    self.errorMessage = "Ollama is not running. Please start Ollama and try again."
                    self.isLoading = false
                }
            }
        }
    }

    func loadModels() {
        isLoading = true
        errorMessage = nil
        print("Starting to load models...")

        Task {
            // First check if Ollama is running
            if !ollamaIsRunning {
                let isRunning = await ollamaService.checkOllamaConnection()
                if !isRunning {
                    await MainActor.run {
                        self.errorMessage = "Ollama is not running. Please start Ollama and try again."
                        self.isLoading = false
                    }
                    return
                } else {
                    await MainActor.run {
                        self.ollamaIsRunning = true
                    }
                }
            }

            do {
                print("Calling ollamaService.listModels()")
                let fetchedModels = try await ollamaService.listModels()
                print("Received \(fetchedModels.count) models from service")

                await MainActor.run {
                    print("Updating UI with models")
                    self.models = fetchedModels
                    self.isLoading = false
                }
            } catch {
                print("Error loading models: \(error)")
                await MainActor.run {
                    self.errorMessage = "Failed to load models: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func loadRunningModels() {
        Task {
            do {
                let fetchedModels = try await ollamaService.listRunningModels()
                DispatchQueue.main.async {
                    self.runningModels = fetchedModels
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load running models: \(error.localizedDescription)"
                }
            }
        }
    }

    func pullModel(name: String) {
        pullProgress[name] = "Starting download..."

        ollamaService.pullModel(name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.pullProgress[name] = "Completed"
                        self?.loadModels()
                    case .failure(let error):
                        self?.pullProgress[name] = "Error: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] status in
                    self?.pullProgress[name] = status
                }
            )
            .store(in: &cancellables)
    }

    func deleteModel(name: String) {
        Task {
            do {
                try await ollamaService.deleteModel(name: name)
                await MainActor.run {
                    // Remove the model from the list
                    self.models.removeAll { $0.name == name }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete model: \(error.localizedDescription)"
                }
            }
        }
    }

    func loadModel(name: String) {
        Task {
            do {
                try await ollamaService.loadModel(name: name)
                await MainActor.run {
                    self.loadRunningModels()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load model: \(error.localizedDescription)"
                }
            }
        }
    }

    func unloadModel(name: String) {
        Task {
            do {
                try await ollamaService.unloadModel(name: name)
                await MainActor.run {
                    self.loadRunningModels()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to unload model: \(error.localizedDescription)"
                }
            }
        }
    }

    func isModelRunning(name: String) -> Bool {
        return runningModels.contains { $0.name == name }
    }

    func formatSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
