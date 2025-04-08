//
//  PullModelView.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct EnhancedPullModelView: View {
    @Binding var isPresented: Bool
    let onPull: (String) -> Void

    @State private var modelName = ""
    @State private var selectedCategory: ModelCategory = .all

    enum ModelCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case llama = "Llama"
        case mistral = "Mistral"
        case code = "Code"
        case multimodal = "Multimodal"

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.large) {
                // Header
                Text("Pull a Model")
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.primaryText)
                    .padding(.top)

                // Model name input
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Model Name")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.secondaryText)

                    HStack {
                        Image(systemName: "cube.box")
                            .foregroundColor(AppColors.secondaryText)

                        TextField("e.g., llama3:8b", text: $modelName)
                            .font(AppFonts.bodyLarge)
                            .textFieldStyle(PlainTextFieldStyle())

                        if !modelName.isEmpty {
                            Button(action: {
                                modelName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(AppSpacing.medium)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppRadius.medium)
                }
                .padding(.horizontal)

                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ModelCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Popular models
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text("Popular Models")
                            .font(AppFonts.title3)
                            .foregroundColor(AppColors.primaryText)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150))
                        ], spacing: AppSpacing.medium) {
                            ForEach(filteredModels, id: \.self) { model in
                                Button(action: {
                                    modelName = model
                                }) {
                                    HStack {
                                        Image(systemName: "cube.fill")
                                            .foregroundColor(AppColors.primary)

                                        Text(model)
                                            .font(AppFonts.bodyMedium)
                                            .foregroundColor(AppColors.primaryText)
                                    }
                                    .padding(AppSpacing.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppRadius.medium)
                                            .fill(modelName == model ? AppColors.primary.opacity(0.1) : AppColors.secondaryBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppRadius.medium)
                                                    .stroke(modelName == model ? AppColors.primary : Color.clear, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }

                // Action buttons
                HStack(spacing: AppSpacing.medium) {
                    AppButton(
                        title: "Cancel",
                        style: .secondary,
                        size: .medium
                    ) {
                        isPresented = false
                    }

                    AppButton(
                        title: "Pull Model",
                        icon: "arrow.down",
                        style: .primary,
                        size: .medium
                    ) {
                        guard !modelName.isEmpty else { return }
                        onPull(modelName)
                        isPresented = false
                    }
                    .disabled(modelName.isEmpty)
                    .opacity(modelName.isEmpty ? 0.6 : 1.0)
                }
                .padding()
            }
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private var filteredModels: [String] {
        switch selectedCategory {
        case .all:
            return allModels
        case .llama:
            return allModels.filter { $0.contains("llama") }
        case .mistral:
            return allModels.filter { $0.contains("mistral") }
        case .code:
            return allModels.filter { $0.contains("code") }
        case .multimodal:
            return allModels.filter { $0.contains("llava") || $0.contains("bakllava") }
        }
    }

    private let allModels = [
        "llama3:8b",
        "llama3:8b-instruct",
        "llama3:70b",
        "llama3:70b-instruct",
        "llama2:7b",
        "llama2:13b",
        "llama2:70b",
        "mistral:7b",
        "mistral:7b-instruct",
        "mixtral:8x7b",
        "codellama:7b",
        "codellama:13b",
        "codellama:34b",
        "llava:13b",
        "llava:34b",
        "bakllava:7b"
    ]
}

#Preview {
    EnhancedPullModelView(isPresented: .constant(true), onPull: { _ in })
}
