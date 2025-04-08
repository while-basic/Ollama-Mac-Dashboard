//
//  EnhancedChatView.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI
import SwiftData

struct EnhancedChatView: View {
    @EnvironmentObject private var viewModel: ModelListViewModel
    @StateObject private var chatViewModel = ChatViewModel()

    @State private var inputText = ""
    @State private var showModelSelector = false
    @State private var showSettingsPopover = false
    @State private var showNewChatConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader

            // Messages area
            messagesView

            // Input area
            ChatInputField(
                text: $inputText,
                onSubmit: sendMessage,
                onClear: { inputText = "" },
                isLoading: chatViewModel.isLoading
            )
        }
        .background(AppColors.background)
        .alert("Start New Chat?", isPresented: $showNewChatConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("New Chat", role: .destructive) {
                chatViewModel.clearMessages()
            }
        } message: {
            Text("This will clear the current conversation. Are you sure you want to continue?")
        }
        .onAppear {
            if chatViewModel.selectedModel == nil && !viewModel.models.isEmpty {
                // Try to select a running model first
                if let runningModel = viewModel.runningModels.first,
                   let model = viewModel.models.first(where: { $0.name == runningModel.name }) {
                    chatViewModel.selectedModel = model
                } else {
                    // Otherwise select the first available model
                    chatViewModel.selectedModel = viewModel.models.first
                }
            }
        }
    }

    private var chatHeader: some View {
        HStack {
            // Model selector
            ModelSelector(
                selectedModel: $chatViewModel.selectedModel,
                models: viewModel.models,
                runningModels: viewModel.runningModels
            )
            .frame(width: 250)

            Spacer()

            // Action buttons
            HStack(spacing: AppSpacing.medium) {
                // New chat button
                Button(action: {
                    if !chatViewModel.messages.isEmpty {
                        showNewChatConfirmation = true
                    } else {
                        chatViewModel.clearMessages()
                    }
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
                .help("New Chat")

                // Settings button
                Button(action: {
                    showSettingsPopover = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Chat Settings")
                .popover(isPresented: $showSettingsPopover, arrowEdge: .top) {
                    ChatSettingsView(
                        temperature: $chatViewModel.temperature,
                        maxTokens: $chatViewModel.maxTokens
                    )
                    .frame(width: 300, height: 200)
                    .padding()
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.secondaryBackground)
            , alignment: .bottom
        )
    }

    private var messagesView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if chatViewModel.messages.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(chatViewModel.messages) { message in
                            ChatBubble(
                                message: message,
                                onCopyContent: {
                                    copyToClipboard(message.content)
                                }
                            )
                            .id(message.id)
                        }

                        // Spacer at the bottom for better scrolling
                        Color.clear.frame(height: 20)
                            .id("bottomSpacer")
                    }
                }
                .padding(.vertical, AppSpacing.medium)
            }
            .onChange(of: chatViewModel.messages) { _, _ in
                // Scroll to bottom when messages change
                withAnimation {
                    scrollView.scrollTo("bottomSpacer", anchor: .bottom)
                }
            }
            .onChange(of: chatViewModel.isLoading) { _, newValue in
                if !newValue {
                    // Scroll to bottom when loading completes
                    withAnimation {
                        scrollView.scrollTo("bottomSpacer", anchor: .bottom)
                    }
                }
            }
        }
        .background(AppColors.background)
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(AppColors.secondaryText.opacity(0.5))

            Text("Start a New Conversation")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.primaryText)

            Text("Select a model and start typing to begin chatting")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            if chatViewModel.selectedModel == nil {
                AppButton(
                    title: "Select a Model",
                    icon: "cube.transparent",
                    style: .primary,
                    size: .medium
                ) {
                    showModelSelector = true
                }
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sendMessage() {
        guard !inputText.isEmpty, let selectedModel = chatViewModel.selectedModel else {
            return
        }

        // Check if model is running, if not, load it
        if !viewModel.isModelRunning(name: selectedModel.name) {
            Task {
                do {
                    try await OllamaService.shared.loadModel(name: selectedModel.name)
                    // Refresh running models after loading
                    viewModel.loadRunningModels()
                } catch {
                    print("Error loading model: \(error)")
                }
            }
        }

        // Send the message
        let messageText = inputText
        inputText = ""
        chatViewModel.sendMessage(messageText)
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct ChatSettingsView: View {
    @Binding var temperature: Double
    @Binding var maxTokens: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text("Chat Settings")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primaryText)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text("Temperature")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.primaryText)

                    Spacer()

                    Text(String(format: "%.1f", temperature))
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.secondaryText)
                }

                Slider(value: $temperature, in: 0...2, step: 0.1)

                Text("Lower values make responses more focused and deterministic. Higher values make responses more creative and varied.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.tertiaryText)
            }

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text("Max Tokens")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.primaryText)

                    Spacer()

                    Text("\(maxTokens)")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.secondaryText)
                }

                Slider(value: Binding(
                    get: { Double(maxTokens) },
                    set: { maxTokens = Int($0) }
                ), in: 100...4096, step: 100)

                Text("Maximum number of tokens to generate. A token is approximately 4 characters.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.tertiaryText)
            }

            Spacer()
        }
    }
}

#Preview {
    EnhancedChatView()
        .environmentObject(ModelListViewModel())
}
