//
//  ModelSelector.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct ModelSelector: View {
    @Binding var selectedModel: OllamaModel?
    let models: [OllamaModel]
    let runningModels: [RunningModel]
    
    @State private var isExpanded = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Selected model button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    if let selectedModel = selectedModel {
                        HStack {
                            Image(systemName: "cube.fill")
                                .foregroundColor(AppColors.primary)
                            
                            VStack(alignment: .leading) {
                                Text(selectedModel.name)
                                    .font(AppFonts.bodyMedium)
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(isModelRunning(name: selectedModel.name) ? AppColors.modelRunning : AppColors.modelStopped)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(isModelRunning(name: selectedModel.name) ? "Running" : "Not Running")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "cube.transparent")
                                .foregroundColor(AppColors.primary)
                            
                            Text("Select a model")
                                .font(AppFonts.bodyMedium)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppColors.secondaryText)
                        .font(.system(size: 12))
                }
                .padding(AppSpacing.medium)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppRadius.medium)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Dropdown content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.secondaryText)
                        
                        TextField("Search models", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(AppFonts.bodyMedium)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(AppSpacing.small)
                    .background(AppColors.background)
                    .cornerRadius(AppRadius.small)
                    
                    // Model list
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Running models section
                            if !filteredRunningModels.isEmpty {
                                Text("Running Models")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(.horizontal, AppSpacing.small)
                                    .padding(.top, AppSpacing.small)
                                
                                ForEach(filteredRunningModels, id: \.id) { model in
                                    modelRow(name: model.name, isRunning: true)
                                }
                                
                                Divider()
                                    .padding(.vertical, AppSpacing.small)
                            }
                            
                            // Available models section
                            Text("Available Models")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.horizontal, AppSpacing.small)
                                .padding(.top, AppSpacing.small)
                            
                            if filteredModels.isEmpty {
                                Text("No models match '\(searchText)'")
                                    .font(AppFonts.bodySmall)
                                    .foregroundColor(AppColors.tertiaryText)
                                    .padding(AppSpacing.medium)
                            } else {
                                ForEach(filteredModels) { model in
                                    modelRow(name: model.name, isRunning: isModelRunning(name: model.name))
                                }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(filteredModels.count + filteredRunningModels.count) * 44 + 80, 300))
                }
                .padding(AppSpacing.small)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppRadius.medium)
                .transition(.opacity)
            }
        }
    }
    
    private func modelRow(name: String, isRunning: Bool) -> some View {
        Button(action: {
            selectedModel = models.first(where: { $0.name == name })
            withAnimation {
                isExpanded = false
            }
        }) {
            HStack {
                Image(systemName: "cube.fill")
                    .foregroundColor(AppColors.primary)
                
                Text(name)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                if isRunning {
                    Circle()
                        .fill(AppColors.modelRunning)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(AppSpacing.medium)
            .background(selectedModel?.name == name ? AppColors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(AppRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var filteredModels: [OllamaModel] {
        if searchText.isEmpty {
            return models
        } else {
            return models.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var filteredRunningModels: [RunningModel] {
        if searchText.isEmpty {
            return runningModels
        } else {
            return runningModels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func isModelRunning(name: String) -> Bool {
        return runningModels.contains { $0.name == name }
    }
}

#Preview {
    ModelSelector(
        selectedModel: .constant(nil),
        models: [
            OllamaModel(
                name: "llama3:8b",
                modifiedAt: Date(),
                size: 4_000_000_000,
                digest: "abc123",
                details: ModelDetails(
                    format: "gguf",
                    family: "llama",
                    families: ["llama"],
                    parameterSize: "8B",
                    quantizationLevel: "Q4_0"
                )
            ),
            OllamaModel(
                name: "mistral:7b",
                modifiedAt: Date(),
                size: 4_000_000_000,
                digest: "def456",
                details: ModelDetails(
                    format: "gguf",
                    family: "mistral",
                    families: ["mistral"],
                    parameterSize: "7B",
                    quantizationLevel: "Q4_0"
                )
            )
        ],
        runningModels: []
    )
    .frame(width: 300)
    .padding()
}
