//
//  BeanjiApp.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 14.08.26.
//

import SwiftUI
import SwiftData

// Central place for app-wide dependency injection
extension EnvironmentValues {
    @Entry var plantAPI: PlantAPI = ApiDecisionControl()

    // Repository-Factory Closure:
    @Entry var makePlantRepository: @MainActor (ModelContext) -> PlantRepository = { modelContext in
        SwiftDataPlantRepository(modelContext: modelContext)
    }
}


@main
struct BeanjiApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Plant.self,
            PlantSpeciesInfo.self,
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
