//
//  MainView.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct MainView: View {
    @State private var selectedModel: OllamaModel?
    @State private var selectedSidebarItem: SidebarItem = .dashboard
    @EnvironmentObject private var viewModel: ModelListViewModel

    enum SidebarItem: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case models = "Models"
        case chat = "Chat"
        case settings = "Settings"

        var id: String { self.rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "gauge"
            case .models: return "cube.stack"
            case .chat: return "bubble.left.and.bubble.right"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
            .navigationTitle("Ollama")
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
        } detail: {
            switch selectedSidebarItem {
            case .dashboard:
                DashboardView()
            case .models:
                NavigationStack {
                    ModelListView(selectedModel: $selectedModel)
                }
            case .chat:
                EnhancedChatView()
            case .settings:
                ContentUnavailableView(
                    "Settings Coming Soon",
                    systemImage: "gear",
                    description: Text("Settings will be available in a future update.")
                )
            }
        }
        .onAppear {
            // Initial data load when the app starts
            if viewModel.models.isEmpty {
                viewModel.checkOllamaConnection()
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(ModelListViewModel())
}
