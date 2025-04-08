//
//  DashboardView.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var viewModel: ModelListViewModel
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Ollama Dashboard")
                            .font(AppFonts.largeTitle)
                            .foregroundColor(AppColors.primaryText)

                        Text("Manage and monitor your Ollama models")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.secondaryText)
                    }

                    Spacer()

                    // Status indicator
                    StatusBadge(
                        type: viewModel.ollamaIsRunning ? .success : .error,
                        text: viewModel.ollamaIsRunning ? "Ollama Running" : "Ollama Stopped"
                    )
                }
                .padding(.bottom, AppSpacing.medium)

                // Quick stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.medium) {
                    StatCard(
                        title: "Total Models",
                        value: "\(viewModel.models.count)",
                        icon: "cube.stack.fill",
                        color: .blue
                    )

                    StatCard(
                        title: "Running Models",
                        value: "\(viewModel.runningModels.count)",
                        icon: "play.circle.fill",
                        color: .green
                    )

                    StatCard(
                        title: "Total Size",
                        value: totalModelSize,
                        icon: "internaldrive.fill",
                        color: .purple
                    )
                }
                .padding(.bottom, AppSpacing.medium)

                // Tabs
                Picker("View", selection: $selectedTab) {
                    Text("Recent Models").tag(0)
                    Text("Running Models").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, AppSpacing.medium)

                // Content based on selected tab
                if selectedTab == 0 {
                    // Recent models
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text("Recent Models")
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.primaryText)

                        if viewModel.models.isEmpty {
                            emptyStateView(
                                title: "No Models Found",
                                message: "Pull your first model to get started",
                                icon: "cube.transparent"
                            )
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 300, maximum: 400))
                            ], spacing: AppSpacing.medium) {
                                ForEach(viewModel.models.prefix(6)) { model in
                                    ModelCard(
                                        model: model,
                                        isRunning: viewModel.isModelRunning(name: model.name),
                                        onSelect: {
                                            // Handle selection
                                        },
                                        onLoad: {
                                            viewModel.loadModel(name: model.name)
                                        },
                                        onUnload: {
                                            viewModel.unloadModel(name: model.name)
                                        },
                                        onDelete: {
                                            // Show delete confirmation
                                        }
                                    )
                                }
                            }

                            if viewModel.models.count > 6 {
                                HStack {
                                    Spacer()

                                    NavigationLink(destination: ModelListView(selectedModel: .constant(nil))) {
                                        Text("View All Models")
                                            .font(AppFonts.bodyMedium)
                                            .foregroundColor(AppColors.primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Spacer()
                                }
                                .padding(.top, AppSpacing.medium)
                            }
                        }
                    }
                } else {
                    // Running models
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text("Running Models")
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.primaryText)

                        if viewModel.runningModels.isEmpty {
                            emptyStateView(
                                title: "No Running Models",
                                message: "Load a model to start using it",
                                icon: "play.slash"
                            )
                        } else {
                            ForEach(viewModel.runningModels, id: \.id) { runningModel in
                                RunningModelRow(model: runningModel) {
                                    viewModel.unloadModel(name: runningModel.name)
                                }
                            }
                        }
                    }
                }

                // Pull new model button
                HStack {
                    Spacer()

                    AppButton(
                        title: "Pull New Model",
                        icon: "arrow.down.circle.fill",
                        style: .primary,
                        size: .large
                    ) {
                        // Show pull sheet
                    }
                    .frame(width: 200)

                    Spacer()
                }
                .padding(.top, AppSpacing.large)
            }
            .padding(AppSpacing.large)
        }
        .background(AppColors.background)
        .onAppear {
            if viewModel.models.isEmpty {
                viewModel.checkOllamaConnection()
            }
        }
        .refreshable {
            await viewModel.refreshAllData()
        }
    }

    private var totalModelSize: String {
        let totalBytes = viewModel.models.map { $0.size }.reduce(0, +)
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }

    private func emptyStateView(title: String, message: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.secondaryText)

            Text(title)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primaryText)

            Text(message)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.large)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(AppFonts.title2)
                .foregroundColor(AppColors.primaryText)

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(AppSpacing.medium)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.medium)
    }
}

struct RunningModelRow: View {
    let model: RunningModel
    let onStop: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(model.name)
                    .font(AppFonts.bodyLarge)
                    .foregroundColor(AppColors.primaryText)

                // expiresAt is not optional in the model
                Text("Expires: \(formatDate(date: model.expiresAt))")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            AppButton(
                title: "Stop",
                icon: "stop.fill",
                style: .secondary,
                size: .small,
                action: onStop
            )
        }
        .padding(AppSpacing.medium)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.medium)
    }

    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
        .environmentObject(ModelListViewModel())
}
