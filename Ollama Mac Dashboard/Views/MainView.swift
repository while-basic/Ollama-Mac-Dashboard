//
//  MainView.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import SwiftUI

struct MainView: View {
    @State private var selectedModel: OllamaModel?
    @EnvironmentObject private var viewModel: ModelListViewModel

    var body: some View {
        NavigationSplitView {
            ModelListView(selectedModel: $selectedModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            if let selectedModel = selectedModel {
                ModelDetailView(model: selectedModel)
            } else {
                ContentUnavailableView(
                    "Select a Model",
                    systemImage: "cube.transparent",
                    description: Text("Choose a model from the sidebar to view details and interact with it.")
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
