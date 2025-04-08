//
//  CodeBlock.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct CodeBlock: View {
    let code: String
    let language: String?
    
    @State private var isCopied = false
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Language header
            if let language = language, !language.isEmpty {
                HStack {
                    Text(language)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, 4)
                    
                    Spacer()
                    
                    Button(action: {
                        copyToClipboard()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12))
                            
                            Text(isCopied ? "Copied!" : "Copy")
                                .font(AppFonts.caption)
                        }
                        .foregroundColor(isCopied ? AppColors.success : AppColors.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.secondaryBackground.opacity(0.5))
                        .cornerRadius(AppRadius.small)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(isHovering || isCopied ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovering || isCopied)
                }
                .padding(.horizontal, AppSpacing.small)
                .background(Color.black.opacity(0.2))
            }
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(AppFonts.code)
                    .padding(AppSpacing.medium)
                    .textSelection(.enabled)
            }
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(AppRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        
        withAnimation {
            isCopied = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

#Preview {
    CodeBlock(
        code: """
        import SwiftUI
        
        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
            }
        }
        """,
        language: "swift"
    )
    .padding()
    .frame(width: 500)
}
