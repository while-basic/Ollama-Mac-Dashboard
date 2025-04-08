//
//  ModelDetailView.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct ModelDetailView: View {
    let model: OllamaModel
    @StateObject private var viewModel = ModelListViewModel()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Model header
                HStack {
                    VStack(alignment: .leading) {
                        Text(model.name)
                            .font(.largeTitle)
                            .bold()

                        Text("Last modified: \(model.modifiedAt, format: .dateTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if viewModel.isModelRunning(name: model.name) {
                        Label("Running", systemImage: "circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding(.bottom)

                // Model details
                GroupBox(label: Label("Model Details", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Parameter Size", value: model.details.parameterSize)
                        DetailRow(label: "Quantization", value: model.details.quantizationLevel)
                        DetailRow(label: "Format", value: model.details.format)
                        DetailRow(label: "Family", value: model.details.family)
                        DetailRow(label: "Size", value: viewModel.formatSize(bytes: model.size))
                        DetailRow(label: "Digest", value: model.digest)
                    }
                    .padding()
                }

                // Actions
                GroupBox(label: Label("Actions", systemImage: "gear")) {
                    VStack(spacing: 12) {
                        if viewModel.isModelRunning(name: model.name) {
                            Button(action: {
                                viewModel.unloadModel(name: model.name)
                            }) {
                                Label("Unload Model", systemImage: "stop.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button(action: {
                                viewModel.loadModel(name: model.name)
                            }) {
                                Label("Load Model", systemImage: "play.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        NavigationLink(destination: ChatView(model: model)) {
                            Label("Chat with Model", systemImage: "message")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete Model", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Model Details")
        .onAppear {
            viewModel.loadRunningModels()
        }
        .alert("Delete Model", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteModel(name: model.name)
            }
        } message: {
            Text("Are you sure you want to delete \(model.name)? This action cannot be undone.")
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

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
