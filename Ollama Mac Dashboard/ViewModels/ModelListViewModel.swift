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

    // Add a timer for automatic refresh of running models
    private var refreshTimer: Timer?

    // Add last refresh timestamps to control refresh frequency
    private var lastModelsRefresh = Date(timeIntervalSince1970: 0)
    private var lastRunningModelsRefresh = Date(timeIntervalSince1970: 0)

    // Minimum time between refreshes (in seconds)
    private let minRefreshInterval: TimeInterval = 5

    @Published var models: [OllamaModel] = []
    @Published var runningModels: [RunningModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pullProgress: [String: String] = [:]
    @Published var ollamaIsRunning = false

    init() {
        // Set up a timer to refresh running models periodically
        setupRefreshTimer()
    }

    deinit {
        // Clean up timer when view model is deallocated
        refreshTimer?.invalidate()
    }

    private func setupRefreshTimer() {
        // Refresh running models every 10 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.refreshRunningModelsIfNeeded()
        }
    }

    private func refreshRunningModelsIfNeeded() {
        // Only refresh if Ollama is running and it's been at least minRefreshInterval since last refresh
        if ollamaIsRunning && Date().timeIntervalSince(lastRunningModelsRefresh) >= minRefreshInterval {
            loadRunningModels()
        }
    }

    func checkOllamaConnection() {
        Task {
            let isRunning = await ollamaService.checkOllamaConnection()
            await MainActor.run {
                self.ollamaIsRunning = isRunning
                if isRunning {
                    self.loadModels()
                    self.loadRunningModels()
                } else {
                    self.errorMessage = "Ollama is not running. Please start Ollama and try again."
                    self.isLoading = false
                }
            }
        }
    }

    func loadModels() {
        // Check if we need to refresh based on time interval
        let now = Date()
        if !isLoading && now.timeIntervalSince(lastModelsRefresh) < minRefreshInterval && !models.isEmpty {
            // Skip refresh if it's too soon and we already have data
            return
        }

        isLoading = true
        errorMessage = nil

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
                let fetchedModels = try await ollamaService.listModels()

                await MainActor.run {
                    self.models = fetchedModels
                    self.lastModelsRefresh = Date()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load models: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func loadRunningModels() {
        // Check if we need to refresh based on time interval
        let now = Date()
        if now.timeIntervalSince(lastRunningModelsRefresh) < minRefreshInterval && !runningModels.isEmpty {
            // Skip refresh if it's too soon and we already have data
            return
        }

        Task {
            do {
                let fetchedModels = try await ollamaService.listRunningModels()

                await MainActor.run {
                    self.runningModels = fetchedModels
                    self.lastRunningModelsRefresh = Date()
                    // Only clear error message if this was successful
                    if self.errorMessage?.contains("running models") == true {
                        self.errorMessage = nil
                    }
                }
            } catch {
                // Only update UI with error if we don't already have data
                if runningModels.isEmpty {
                    await MainActor.run {
                        if let ollamaError = error as? OllamaError, case .decodingError(let decodingError) = ollamaError {
                            self.errorMessage = "Failed to load running models: \(decodingError.localizedDescription)"
                        } else {
                            self.errorMessage = "Failed to load running models: \(error.localizedDescription)"
                        }
                    }
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

    // Add a method to refresh all data at once for pull-to-refresh
    func refreshAllData() async {
        // Force refresh by resetting timestamps
        lastModelsRefresh = Date(timeIntervalSince1970: 0)
        lastRunningModelsRefresh = Date(timeIntervalSince1970: 0)

        // First check connection
        let isRunning = await ollamaService.checkOllamaConnection()

        await MainActor.run {
            self.ollamaIsRunning = isRunning
        }

        if isRunning {
            // Load models first
            loadModels()

            // Then load running models
            loadRunningModels()
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
