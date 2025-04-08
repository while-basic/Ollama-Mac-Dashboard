//
//  AppButton.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

enum AppButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case success
}

enum AppButtonSize {
    case small
    case medium
    case large
}

struct AppButton: View {
    let title: String
    let icon: String?
    let style: AppButtonStyle
    let size: AppButtonSize
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        style: AppButtonStyle = .primary,
        size: AppButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(iconFont)
                }
                
                Text(title)
                    .font(textFont)
            }
            .padding(padding)
            .frame(height: height)
            .frame(maxWidth: size == .large ? .infinity : nil)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(AppRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.white
        case .secondary:
            return AppColors.primary
        case .tertiary:
            return AppColors.primaryText
        case .destructive:
            return style == .tertiary ? AppColors.error : Color.white
        case .success:
            return style == .tertiary ? AppColors.success : Color.white
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppColors.primary
        case .secondary:
            return Color.clear
        case .tertiary:
            return Color.clear
        case .destructive:
            return style == .tertiary ? Color.clear : AppColors.error
        case .success:
            return style == .tertiary ? Color.clear : AppColors.success
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.clear
        case .secondary:
            return AppColors.primary
        case .tertiary:
            return Color.clear
        case .destructive:
            return style == .tertiary ? Color.clear : AppColors.error
        case .success:
            return style == .tertiary ? Color.clear : AppColors.success
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .secondary:
            return 1
        default:
            return 0
        }
    }
    
    private var padding: EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        case .medium:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .large:
            return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        }
    }
    
    private var height: CGFloat {
        switch size {
        case .small:
            return 28
        case .medium:
            return 36
        case .large:
            return 44
        }
    }
    
    private var textFont: Font {
        switch size {
        case .small:
            return AppFonts.bodySmall
        case .medium:
            return AppFonts.bodyMedium
        case .large:
            return AppFonts.bodyLarge
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small:
            return .system(size: 12)
        case .medium:
            return .system(size: 14)
        case .large:
            return .system(size: 16)
        }
    }
}
