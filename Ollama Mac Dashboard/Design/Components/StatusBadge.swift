//
//  StatusBadge.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

enum StatusType {
    case running
    case stopped
    case loading
    case error
    case warning
    case success
    case info
    
    var color: Color {
        switch self {
        case .running:
            return AppColors.modelRunning
        case .stopped:
            return AppColors.modelStopped
        case .loading:
            return AppColors.info
        case .error:
            return AppColors.error
        case .warning:
            return AppColors.warning
        case .success:
            return AppColors.success
        case .info:
            return AppColors.info
        }
    }
    
    var icon: String {
        switch self {
        case .running:
            return "circle.fill"
        case .stopped:
            return "circle.slash"
        case .loading:
            return "arrow.clockwise"
        case .error:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

struct StatusBadge: View {
    let type: StatusType
    let text: String
    let showIcon: Bool
    
    init(type: StatusType, text: String, showIcon: Bool = true) {
        self.type = type
        self.text = text
        self.showIcon = showIcon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: type.icon)
                    .font(.system(size: 10))
            }
            
            Text(text)
                .font(AppFonts.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(type.color.opacity(0.2))
        .foregroundColor(type.color)
        .cornerRadius(AppRadius.small)
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBadge(type: .running, text: "Running")
        StatusBadge(type: .stopped, text: "Stopped")
        StatusBadge(type: .loading, text: "Loading")
        StatusBadge(type: .error, text: "Error")
        StatusBadge(type: .warning, text: "Warning")
        StatusBadge(type: .success, text: "Success")
        StatusBadge(type: .info, text: "Information")
    }
    .padding()
}
