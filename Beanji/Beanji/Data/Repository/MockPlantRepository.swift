//
//  MockPlantRepository.swift
//  StudentProjekt
//
//  Created by Eugenia Fanenstiel on 24.06.26.
//
//  MARK: Mockdata for Preview & Testing

import Foundation

final class MockPlantRepository: PlantRepository {

    var mockPlants: [Plant] = [
        Plant(
            name: "Tomato",
            speciesName: "Solanum lycopersicum",
            lastWatered: Date(),
            lastFertilized: Date(),
            wateringIntervalDays: 3,
            fertilizingIntervalDays: 14,
            imageName: nil,
            createdAt: Date(),
            notes: nil,
            photoData: nil,
            

        ),
        Plant(
            name: "Basil",
            speciesName: "Ocimum basilicum",
            lastWatered: Date(),
            lastFertilized: Date(),
            wateringIntervalDays: 2,
            fertilizingIntervalDays: 14,
            imageName: nil,
            createdAt: Date(),
            notes: nil,
            photoData: nil
        ),
        Plant(
            name: "Monstera",
            speciesName: "Monstera deliciosa",
            lastWatered: Date(),
            lastFertilized: Date(),
            wateringIntervalDays: 7,
            fertilizingIntervalDays: 30,
            imageName: nil,
            createdAt: Date(),
            notes: nil,
            photoData: nil
        ),
        Plant(
            name: "Lavender",
            speciesName: "Lavandula angustifolia",
            lastWatered: Date(),
            lastFertilized: Date(),
            wateringIntervalDays: 5,
            fertilizingIntervalDays: 21,
            imageName: nil,
            createdAt: Date(),
            notes: nil,
            photoData: nil
        ),
        Plant(
            name: "Rosemary",
            speciesName: "Salvia rosmarinus",
            lastWatered: Date(),
            lastFertilized: Date(),
            wateringIntervalDays: 5,
            fertilizingIntervalDays: 21,
            imageName: nil,
            createdAt: Date(),
            notes: nil,
            photoData: nil
        ),
    ]

    
    // Getting all plants, sorted in decending order by creation date (newest first)
    func fetchAllPlants() async throws -> [Plant] {
        return mockPlants.sorted { $0.createdAt > $1.createdAt }
    }

    // Fetches plants based on search text and filter criteria.
    func fetchPlants(searchText: String?, filter: String?) async throws
        -> [Plant]
    {
        var result = mockPlants
        if let searchText = searchText, !searchText.isEmpty {
            result = result.filter { plant in
                plant.name.localizedCaseInsensitiveContains(searchText)
                    || plant.speciesName.localizedCaseInsensitiveContains(
                        searchText
                    )
            }
        }
        return result
    }

    // Saves new plant to the mock repository
    func savePlant(_ plant: Plant) async throws {
        mockPlants.append(plant)
    }

    // Adds new plant to the mock repository based on the selected species and userprovided name
    func addSpeciesToMyPlants(from species: PlantSpecies, userPlantName: String?) async throws
        -> Plant
    {
        let speciesInfo = PlantSpeciesInfo(from: species)

        let plant = Plant(
            name: userPlantName?.isEmpty == false ? userPlantName! : species.commonName,
            speciesName: species.scientificName,
            lastWatered: Date(),
            lastFertilized: Date(),
            wateringIntervalDays: 3,
            fertilizingIntervalDays: 30,
            createdAt: Date(),
            notes: nil,
            photoData: nil,
            location: nil,
            speciesInfo: speciesInfo
        )
        mockPlants.append(plant)
        return plant
    }

    //  Deletes plant from the mock repository
    func deletePlant(_ plant: Plant) async throws {
        mockPlants.removeAll { $0.id == plant.id }
    }

    // Updates an existing plant in the mock repository
    func updatePlant(_ plant: Plant) async throws {
        guard let index = mockPlants.firstIndex(where: { $0.id == plant.id })
        else { return }
        mockPlants[index] = plant
    }

    
    func refreshPlantSpeciesInfo(for plant: Plant, plantAPI: PlantAPI)
        async throws
    {
        // TODO: need to be implemented for mock repository, but not needed for now
    }
}
