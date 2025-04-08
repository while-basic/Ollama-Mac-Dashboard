//
//  Ollama_Mac_DashboardApp.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI
import SwiftData

@main
struct Ollama_Mac_DashboardApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChatMessage.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
