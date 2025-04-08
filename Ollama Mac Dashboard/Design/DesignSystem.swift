//
//  DesignSystem.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

// MARK: - Color Palette
struct AppColors {
    // Primary colors
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    static let accent = Color("AccentColor")

    // Semantic colors
    static let success = Color("SuccessColor")
    static let warning = Color("WarningColor")
    static let error = Color("ErrorColor")
    static let info = Color("InfoColor")

    // Background colors
    static let background = Color("BackgroundColor")
    static let secondaryBackground = Color("SecondaryBackgroundColor")
    static let tertiaryBackground = Color("TertiaryBackgroundColor")

    // Text colors
    static let primaryText = Color("PrimaryTextColor")
    static let secondaryText = Color("SecondaryTextColor")
    static let tertiaryText = Color("TertiaryTextColor")

    // Model status colors
    static let modelRunning = Color("ModelRunningColor")
    static let modelStopped = Color("ModelStoppedColor")
    static let modelLoading = Color("ModelLoadingColor")
}

// MARK: - Typography
struct AppFonts {
    // Heading fonts
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    // Body fonts
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // Special fonts
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let footnote = Font.system(size: 11, weight: .regular, design: .default)
    static let code = Font.system(size: 15, weight: .regular, design: .monospaced)
}

// MARK: - Spacing
struct AppSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Radius
struct AppRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let xl: CGFloat = 16
    static let circle: CGFloat = 9999
}

// MARK: - Shadows
struct AppShadows {
    static let small = ShadowStyle(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    static let medium = ShadowStyle(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    static let large = ShadowStyle(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Animation
struct AppAnimation {
    static let standard = Animation.easeInOut(duration: 0.3)
    static let quick = Animation.easeOut(duration: 0.15)
    static let slow = Animation.easeInOut(duration: 0.5)
}
