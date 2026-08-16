//
//  BeanjiApp.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 14.08.26.
//

import SwiftUI
import SwiftData

// Production dependencies are assembled at the app boundary.
extension EnvironmentValues {
    @Entry var plantCatalog: PlantCatalogRepository = LocalPlantCatalog()

    @Entry var makeUserPlantRepository:
        @MainActor (ModelContext) -> UserPlantRepository = { modelContext in
            SwiftDataUserPlantRepository(modelContext: modelContext)
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
