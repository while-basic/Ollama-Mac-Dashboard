//
//  EnhancedModelRow.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct EnhancedModelRow: View, Equatable {
    let model: OllamaModel
    let isRunning: Bool
    let onSelect: () -> Void

    // Add Equatable conformance to avoid unnecessary redraws
    static func == (lhs: EnhancedModelRow, rhs: EnhancedModelRow) -> Bool {
        return lhs.model.id == rhs.model.id &&
               lhs.isRunning == rhs.isRunning
    }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Model icon
                ZStack {
                    Circle()
                        .fill(AppColors.secondaryBackground)
                        .frame(width: 40, height: 40)

                    Image(systemName: "cube.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                }

                // Model details
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(model.name)
                        .font(AppFonts.bodyLarge)
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.small) {
                        Text(model.details.parameterSize)
                            .font(AppFonts.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(Color.blue)
                            .cornerRadius(AppRadius.small)

                        Text(model.details.quantizationLevel)
                            .font(AppFonts.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(Color.purple)
                            .cornerRadius(AppRadius.small)

                        Text(model.details.family)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }

                Spacer()

                // Status indicator
                if isRunning {
                    StatusBadge(type: .running, text: "Running", showIcon: true)
                }
            }
            .padding(AppSpacing.medium)
            .background(AppColors.background)
            .cornerRadius(AppRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(AppColors.secondaryBackground, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EnhancedModelRow(
        model: OllamaModel(
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
        isRunning: true,
        onSelect: {}
    )
    .padding()
}
