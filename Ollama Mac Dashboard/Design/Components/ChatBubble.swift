//
//  ChatBubble.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

enum MessageRole {
    case user
    case assistant
    case system
    
    var color: Color {
        switch self {
        case .user:
            return AppColors.primary
        case .assistant:
            return AppColors.secondaryBackground
        case .system:
            return AppColors.info.opacity(0.2)
        }
    }
    
    var textColor: Color {
        switch self {
        case .user:
            return Color.white
        case .assistant:
            return AppColors.primaryText
        case .system:
            return AppColors.info
        }
    }
    
    var alignment: Alignment {
        switch self {
        case .user:
            return .trailing
        case .assistant, .system:
            return .leading
        }
    }
    
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .user:
            return .trailing
        case .assistant, .system:
            return .leading
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let onCopyContent: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: messageRole.horizontalAlignment) {
            // Message header
            HStack {
                if messageRole == .assistant {
                    Image(systemName: "cube.transparent.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 14))
                    
                    Text(message.modelName)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                } else if messageRole == .user {
                    Spacer()
                    
                    Text("You")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 8)
            
            // Message bubble
            HStack {
                if messageRole == .user {
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    MarkdownText(message.content)
                        .padding(AppSpacing.medium)
                }
                .background(messageRole.color)
                .foregroundColor(messageRole.textColor)
                .cornerRadius(AppRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .stroke(messageRole == .assistant ? AppColors.secondaryBackground.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                .overlay(
                    HStack {
                        if isHovering {
                            Button(action: onCopyContent) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(6)
                                    .background(AppColors.background.opacity(0.8))
                                    .cornerRadius(AppRadius.small)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.opacity)
                        }
                    }
                    .padding(4)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                    , alignment: .topTrailing
                )
                .onHover { hovering in
                    isHovering = hovering
                }
                
                if messageRole == .assistant {
                    Spacer()
                }
            }
            
            // Timestamp
            Text(formatTimestamp(message.timestamp))
                .font(AppFonts.footnote)
                .foregroundColor(AppColors.tertiaryText)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .frame(maxWidth: .infinity, alignment: messageRole.alignment)
    }
    
    private var messageRole: MessageRole {
        switch message.role {
        case "user":
            return .user
        case "assistant":
            return .assistant
        case "system":
            return .system
        default:
            return .user
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MarkdownText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(attributedString)
            .textSelection(.enabled)
    }
    
    private var attributedString: AttributedString {
        do {
            // Simple markdown parsing for now
            var attributedString = try AttributedString(markdown: text)
            
            // Set default font
            attributedString.font = AppFonts.bodyMedium
            
            return attributedString
        } catch {
            return AttributedString(text)
        }
    }
}

#Preview {
    VStack {
        ChatBubble(
            message: ChatMessage(
                role: "user",
                content: "Hello, can you help me understand how transformers work?",
                modelName: "llama3:8b"
            ),
            onCopyContent: {}
        )
        
        ChatBubble(
            message: ChatMessage(
                role: "assistant",
                content: "Transformers are a type of neural network architecture that has revolutionized natural language processing. They use a mechanism called **self-attention** to weigh the importance of different words in a sentence.\n\nHere's a simple example in code:\n```python\nimport torch\nfrom transformers import AutoModel\n\nmodel = AutoModel.from_pretrained('bert-base-uncased')\n```",
                modelName: "llama3:8b"
            ),
            onCopyContent: {}
        )
    }
    .padding()
    .background(AppColors.background)
}
