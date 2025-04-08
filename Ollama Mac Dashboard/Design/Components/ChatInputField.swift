//
//  ChatInputField.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct ChatInputField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    let onSubmit: () -> Void
    let onClear: () -> Void
    let isLoading: Bool

    @State private var height: CGFloat = 40
    private let minHeight: CGFloat = 40
    private let maxHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: {
                    // Add attachment (future feature)
                }) {
                    Image(systemName: "paperclip")
                        .foregroundColor(AppColors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoading)

                Spacer()

                Button(action: onClear) {
                    Text("Clear")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(text.isEmpty ? 0 : 1)
                .disabled(text.isEmpty || isLoading)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.small)

            // Input field
            HStack(alignment: .bottom, spacing: AppSpacing.medium) {
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if text.isEmpty {
                        Text("Type a message...")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.tertiaryText)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .opacity(isFocused ? 0.5 : 1.0)
                    }

                    // Actual text input
                    TextEditor(text: $text)
                        .font(AppFonts.bodyMedium)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(height: height)
                        .onChange(of: text) { _, newValue in
                            updateHeight(text: newValue)
                        }
                        .disabled(isLoading)
                }
                .frame(height: height)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppRadius.medium)

                // Send button
                Button(action: {
                    if !text.isEmpty && !isLoading {
                        onSubmit()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 36, height: 36)

                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(text.isEmpty || isLoading)
                .opacity(text.isEmpty ? 0.6 : 1.0)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
        }
        .background(AppColors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.secondaryBackground)
            , alignment: .top
        )
        .onAppear {
            isFocused = true
        }
    }

    private func updateHeight(text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ]

        let width = NSScreen.main.frame.width - 100 // Approximate width
        let estimatedFrame = NSString(string: text)
            .boundingRect(
                with: CGSize(width: width, height: .infinity),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )

        let calculatedHeight = estimatedFrame.height + 30
        height = min(max(calculatedHeight, minHeight), maxHeight)
    }
}

// Helper for macOS
extension NSScreen {
    static var main: NSScreen {
        return NSScreen.main ?? NSScreen.screens.first!
    }
}

#Preview {
    VStack {
        Spacer()
        ChatInputField(
            text: .constant(""),
            onSubmit: {},
            onClear: {},
            isLoading: false
        )
    }
}
