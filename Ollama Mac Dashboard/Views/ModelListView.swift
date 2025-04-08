//
//  ModelListView.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct ModelListView: View {
    @EnvironmentObject private var viewModel: ModelListViewModel
    @State private var showingPullSheet = false
    @State private var modelToPull = ""
    @Binding var selectedModel: OllamaModel?
    @State private var isRefreshing = false

    var body: some View {
        VStack {
            if !viewModel.ollamaIsRunning && viewModel.errorMessage != nil {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text(viewModel.errorMessage ?? "")
                        .multilineTextAlignment(.center)

                    Button("Retry Connection") {
                        viewModel.checkOllamaConnection()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    Section(header: Text("Installed Models")) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if viewModel.models.isEmpty {
                            Text("No models installed")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.models) { model in
                                // Use Button instead of onTapGesture for better responsiveness
                                Button(action: {
                                    // Immediately update selection for better responsiveness
                                    selectedModel = model
                                }) {
                                    ModelRow(model: model, isRunning: viewModel.isModelRunning(name: model.name))
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle()) // Use plain style to avoid button styling
                                .contextMenu {
                                    if viewModel.isModelRunning(name: model.name) {
                                        Button("Unload Model") {
                                            viewModel.unloadModel(name: model.name)
                                        }
                                    } else {
                                        Button("Load Model") {
                                            viewModel.loadModel(name: model.name)
                                        }
                                    }

                                    Button("Delete Model", role: .destructive) {
                                        viewModel.deleteModel(name: model.name)
                                    }
                                }
                            }
                        }
                    }

                    if !viewModel.runningModels.isEmpty {
                        Section(header: Text("Running Models")) {
                            ForEach(viewModel.runningModels) { model in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(model.name)
                                            .font(.headline)
                                        Text("Size: \(viewModel.formatSize(bytes: model.sizeVram))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 10, height: 10)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    if !viewModel.pullProgress.isEmpty {
                        Section(header: Text("Downloads")) {
                            ForEach(Array(viewModel.pullProgress.keys), id: \.self) { model in
                                if let progress = viewModel.pullProgress[model] {
                                    HStack {
                                        Text(model)
                                        Spacer()
                                        Text(progress)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Models")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            showingPullSheet = true
                        }) {
                            Label("Pull Model", systemImage: "arrow.down.circle")
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            viewModel.loadModels()
                            viewModel.loadRunningModels()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
                .sheet(isPresented: $showingPullSheet) {
                    PullModelView(isPresented: $showingPullSheet, onPull: { modelName in
                        viewModel.pullModel(name: modelName)
                    })
                }
                .onAppear {
                    // Only load data if it hasn't been loaded yet
                    if viewModel.models.isEmpty {
                        viewModel.checkOllamaConnection()
                    } else {
                        // Just refresh running models which is a lighter operation
                        viewModel.loadRunningModels()
                    }
                }
                .refreshable {
                    // Set refreshing state to show visual feedback
                    isRefreshing = true

                    // Use a Task to handle async operations
                    await viewModel.refreshAllData()

                    // Reset refreshing state
                    isRefreshing = false
                }
            }
        }
        .alert(item: Binding<AlertItem?>(
            get: { viewModel.errorMessage.map { AlertItem(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { alert in
            Alert(
                title: Text("Error"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Make ModelRow more efficient with Equatable
struct ModelRow: View, Equatable {
    let model: OllamaModel
    let isRunning: Bool

    // Add Equatable conformance to avoid unnecessary redraws
    static func == (lhs: ModelRow, rhs: ModelRow) -> Bool {
        return lhs.model.id == rhs.model.id &&
               lhs.isRunning == rhs.isRunning
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                    .lineLimit(1) // Limit to one line for better performance

                HStack {
                    Text(model.details.parameterSize)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)

                    Text(model.details.quantizationLevel)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(4)
                }

                Text("Family: \(model.details.family)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1) // Limit to one line for better performance
            }

            Spacer()

            if isRunning {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PullModelView: View {
    @Binding var isPresented: Bool
    let onPull: (String) -> Void

    @State private var modelName = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Model Information")) {
                    TextField("Model Name (e.g., llama3:8b)", text: $modelName)
                }

                Section {
                    Button("Pull Model") {
                        guard !modelName.isEmpty else { return }
                        onPull(modelName)
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }

                Section(header: Text("Popular Models")) {
                    ForEach(popularModels, id: \.self) { model in
                        Button(model) {
                            modelName = model
                        }
                    }
                }
            }
            .navigationTitle("Pull Model")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private let popularModels = [
        "llama3:8b",
        "llama3:70b",
        "mistral:7b",
        "codellama:7b",
        "llava:13b"
    ]
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    ModelListView(selectedModel: .constant(nil))
}
