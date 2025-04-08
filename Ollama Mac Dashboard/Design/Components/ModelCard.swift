//
//  ModelCard.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct ModelCard: View {
    let model: OllamaModel
    let isRunning: Bool
    let onSelect: () -> Void
    let onLoad: () -> Void
    let onUnload: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(model.name)
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)

                    Text(model.details.family)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

                StatusBadge(
                    type: isRunning ? .running : .stopped,
                    text: isRunning ? "Running" : "Stopped"
                )
            }

            // Model details
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    TagView(text: model.details.parameterSize, color: .blue)
                    TagView(text: model.details.quantizationLevel, color: .purple)
                }

                Text("Size: \(formatSize(bytes: model.size))")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.secondaryText)

                Text("Modified: \(formatDate(date: model.modifiedAt))")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.tertiaryText)
            }

            // Action buttons
            HStack {
                if isRunning {
                    AppButton(
                        title: "Unload",
                        icon: "stop.fill",
                        style: .secondary,
                        size: .small,
                        action: onUnload
                    )
                } else {
                    AppButton(
                        title: "Load",
                        icon: "play.fill",
                        style: .primary,
                        size: .small,
                        action: onLoad
                    )
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.error)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.medium)
        .shadow(radius: isHovering ? 4 : 2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }

    private func formatSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppFonts.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(AppRadius.small)
    }
}
