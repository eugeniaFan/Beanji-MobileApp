//
//  SwiftDataUserPlantRepository.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 25.06.26.
//
//  Persists the user's plants with SwiftData.

import Foundation
import SwiftData

@MainActor
final class SwiftDataUserPlantRepository: UserPlantRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Fetch Methods

    func fetchAllPlants() throws -> [Plant] {
        let descriptor = FetchDescriptor<Plant>(sortBy: [
            SortDescriptor(\.createdAt, order: .reverse)
        ])
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw UserPlantRepositoryError.fetchFailed(underlying: error)
        }
    }

    func fetchPlants(searchText: String?, filter: String?) throws -> [Plant] {
        var descriptor = FetchDescriptor<Plant>(sortBy: [
            SortDescriptor(\.createdAt, order: .reverse)
        ])

        if let searchText, !searchText.isEmpty {
            descriptor.predicate = #Predicate { plant in
                plant.name.localizedStandardContains(searchText)
                    || plant.speciesName.localizedStandardContains(searchText)
            }
        }

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw UserPlantRepositoryError.fetchFailed(underlying: error)
        }

    }

    // MARK: - CRUD Operations

    func savePlant(_ plant: Plant) async throws {
        modelContext.insert(plant)

        do {
            try modelContext.save()
        } catch {
            throw UserPlantRepositoryError.saveFailed(
                underlying: error
            )
        }
    }

    func deletePlant(_ plant: Plant) async throws {
        modelContext.delete(plant)

        do {
            try modelContext.save()
        } catch {
            throw UserPlantRepositoryError.deleteFailed(
                underlying: error
            )
        }
    }

    func updatePlant(_ plant: Plant) async throws {
        do {
            try modelContext.save()
        } catch {
            throw UserPlantRepositoryError.updateFailed(
                underlying: error
            )
        }
    }

    func addSpeciesToMyPlants(
        from species: PlantSpecies,
        userPlantName: String?
    ) async throws -> Plant {
        do {
            let speciesInfo = try upsertSpeciesInfo(from: species)
            // Cache remote images so saved plants remain available offline.
            var photoData: Data? = nil
            if let imageUrlString = species.imageUrl,
                let imageUrl = URL(string: imageUrlString)
            {
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

        } catch {
            throw UserPlantRepositoryError.saveFailed(underlying: error)
        }
    }

    private func upsertSpeciesInfo(from species: PlantSpecies) throws -> PlantSpeciesInfo {
        let speciesId = species.speciesId

        let descriptor = FetchDescriptor<PlantSpeciesInfo>(
            predicate: #Predicate<PlantSpeciesInfo> { info in
                info.speciesInfoId == speciesId
            }
        )

        if let existingInfo = try modelContext.fetch(descriptor).first {
            existingInfo.update(from: species)
            return existingInfo
        }

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

        let cleaned =
            value
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.contains("-") {
            let firstValue = cleaned.split(separator: "-").first
            return Int(firstValue ?? "") ?? 7
        }

        return Int(cleaned) ?? 7
    }

    // MARK: - Species Refresh
    func refreshPlantSpeciesInfo(
        for plant: Plant,
        using provider: PlantSpeciesProvider
    ) async throws {
        guard let speciesInfo = plant.speciesInfo else { return }

        let latestSpecies = try await provider.getPlantDetail(
            id: speciesInfo.speciesInfoId
        )

        speciesInfo.update(from: latestSpecies)

        do {
            try modelContext.save()
        } catch {
            throw UserPlantRepositoryError.updateFailed(
                underlying: error
            )
        }
    }
}
