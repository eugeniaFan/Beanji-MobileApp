//
//  InMemoryUserPlantRepository.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 24.06.26.
//
//  In-memory repository for previews and tests.

import Foundation

final class InMemoryUserPlantRepository: UserPlantRepository {

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

    
    func fetchAllPlants() throws -> [Plant] {
        return mockPlants.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchPlants(searchText: String?, filter: String?) throws -> [Plant] {
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

    func savePlant(_ plant: Plant) throws {
        mockPlants.append(plant)
    }
    
    func deletePlant(_ plant: Plant) throws {
        mockPlants.removeAll { $0.id == plant.id }
    }

    func updatePlant(_ plant: Plant) throws {
        guard let index = mockPlants.firstIndex(
            where: { $0.id == plant.id }
        ) else {
            return
        }
        
        mockPlants[index] = plant
    }
    
    
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

    
    func refreshPlantSpeciesInfo(for plant: Plant, using provider: PlantSpeciesProvider)
        async throws
    {
        // In-memory data intentionally skips provider refreshes.
    }
}
