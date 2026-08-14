//
//  SwiftDataPlantRepository.swift
//  StudentProjekt
//
//  Created by Eugenia Fanenstiel on 25.06.26.
//
//  MARK: holds ModelContext, talks to SwiftData

import Foundation
import SwiftData


@MainActor
final class SwiftDataPlantRepository: PlantRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Fetch Methods
    
    // Fetches all plants, ordered by creation date (newest first).
    func fetchAllPlants() async throws -> [Plant] {
        let descriptor = FetchDescriptor<Plant>(sortBy: [
            SortDescriptor(\.createdAt, order: .reverse)
        ])
        return try modelContext.fetch(descriptor)
    }

    func fetchPlants(searchText: String?, filter: String?) async throws -> [Plant] {
        
        var descriptor = FetchDescriptor<Plant>(sortBy: [
            SortDescriptor(\.createdAt, order: .reverse)
        ])

        if let searchText, !searchText.isEmpty {
            descriptor.predicate = #Predicate { plant in
                plant.name.localizedStandardContains(searchText)
                    || plant.speciesName.localizedStandardContains(searchText)
            }
        }
    
        return try modelContext.fetch(descriptor)
    }

    // MARK: - CRUD Operations
    
    // TODO: more error handling and check for asyn operations
    func savePlant(_ plant: Plant) async throws {
        modelContext.insert(plant)
        try modelContext.save()
    }
    
    func deletePlant(_ plant: Plant) async throws {
        modelContext.delete(plant)
        try modelContext.save()
    }

    func updatePlant(_ plant: Plant) async throws {
        try modelContext.save()
    }
    
    // Creates or updates a PlantSpeciesInfo entity in SwiftData and associates it with the new Plant
    func addSpeciesToMyPlants(from species: PlantSpecies, userPlantName: String?) async throws -> Plant {
       
        let speciesInfo = try upsertSpeciesInfo(from: species)
        // Download image data so it is available offline in "Meine Pflanzen"
                var photoData: Data? = nil
                if let imageUrlString = species.imageUrl, let imageUrl = URL(string: imageUrlString) {
                    photoData = try? await URLSession.shared.data(from: imageUrl).0
                }

        let plant = Plant(
            name: userPlantName?.isEmpty == false
                ? userPlantName!
            : species.commonName,
            speciesName: species.scientificName,
            lastWatered: Date(),
            lastFertilized: Date(),
            wateringIntervalDays: wateringIntervalDays(from: species),
            fertilizingIntervalDays: 30,
            createdAt: Date(),
            notes: nil,
            photoData: photoData,
            location: nil,
            speciesInfo: speciesInfo
        )

        modelContext.insert(plant)
        try modelContext.save()

        return plant
    }
        
    // Finds existing species info or creates a new one.
    private func upsertSpeciesInfo(from species: PlantSpecies) throws -> PlantSpeciesInfo {
        let speciesId = species.speciesId
        
        // Check if a PlantSpeciesInfo object already exists in SwiftData
        let descriptor = FetchDescriptor<PlantSpeciesInfo>(
            predicate: #Predicate<PlantSpeciesInfo> { info in
                info.speciesInfoId == speciesId
            }
        )
        
        // Update existing PlantSpeciesInfo Object with same speciesId
        if let existingInfo = try modelContext.fetch(descriptor).first {
            existingInfo.update(from: species)
            return existingInfo
        }
        
        // Create a new PlantSpeciesInfo Object and insert it into SwiftData
        let newInfo = PlantSpeciesInfo(from: species)
        modelContext.insert(newInfo)
        return newInfo
    }

    
    private func wateringIntervalDays(from species: PlantSpecies) -> Int {
        guard let value = species.wateringFrequency?.value else {
            switch species.watering?.lowercased() {
            case "frequent":
                return 3
            case "minimum":
                return 10
            case "average":
                return 7
            default:
                return 7
            }
        }

        let cleaned = value
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.contains("-") {
            let firstValue = cleaned.split(separator: "-").first
            return Int(firstValue ?? "") ?? 7
        }

        return Int(cleaned) ?? 7
    }

    
    // MARK: - Refresh method
    
    // This method fetches the latest species info from the API and updates the local database.
    func refreshPlantSpeciesInfo(for plant: Plant, plantAPI: PlantAPI) async throws {
        guard let plantSpeciesInfo = plant.speciesInfo else { return }
        let latestPlantSpecies = try await plantAPI.getPlantDetail(id: plantSpeciesInfo.speciesInfoId)

        plantSpeciesInfo.update(from: latestPlantSpecies)
        try modelContext.save()
    }
}
