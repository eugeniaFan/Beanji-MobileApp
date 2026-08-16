//
//  ContentView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 14.08.26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.plantCatalog) private var plantCatalog
    @Environment(\.makePlantRepository) private var makePlantRepository
    @State private var allplantsViewModel: AllPlantsViewModel?

    var body: some View {
        TabView {
            CareTasksView(
                viewModel: CareTasksViewModel(
                    repository: makePlantRepository(modelContext)
                )
            )
            .tabItem {
                Label("Care Tasks", systemImage: "drop.fill")
            }
            Group {
                if let allplantsViewModel {
                    AllPlantsView(viewModel: allplantsViewModel)
                } else {
                    ProgressView()
                }
            }
            .tabItem {
                Label("Pflanzen", systemImage: "leaf.fill")
            }
        }
        .task {
            guard allplantsViewModel == nil else { return }
            allplantsViewModel = AllPlantsViewModel(
                catalogService: plantCatalog,
                repository: makePlantRepository(modelContext)
            )
        }
    }
}

#Preview {
    ContentView()
        .environment(\.plantCatalog, PreviewPlantProvider())
        .environment(\.makePlantRepository) { _ in
            MockPlantRepository()
        }
        .modelContainer(
            for: [Plant.self, PlantSpeciesInfo.self],
            inMemory: true
        )
}
