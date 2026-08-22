//
//  PreviewPlantProvider.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 13.06.26.
//
//  Provides stable sample data for SwiftUI previews.

import Foundation

struct PreviewPlantProvider: PlantCatalogRepository {
    
    static let samplePlants: [PlantSpecies] = [
        PlantSpecies(
            speciesId: 1,
            commonName: "Aloe Vera",
            scientificName: "Aloe barbadensis miller",
            watering: "Minimum",
            wateringFrequency: WateringFrequency(unit: "days", value: "14"),
            sunlight: ["full sun", "part shade"],
            maintenance: "Low",
            indoor: true,
            imageUrl: nil,
            careLevel: "Easy",
            description:
                "Aloe vera is a low-maintenance succulent that needs little water.",
        ),
        PlantSpecies(
            speciesId: 2,
            commonName: "Monstera",
            scientificName: "Monstera deliciosa",
            watering: "Average",
            wateringFrequency: WateringFrequency(unit: "days", value: "7"),
            sunlight: ["part shade"],
            maintenance: "Low",
            indoor: true,
            imageUrl: nil,
            careLevel: "Easy",
            description:
                "Monstera prefers indirect light and develops large split leaves.",
        ),
        PlantSpecies(
            speciesId: 3,
            commonName: "Basil",
            scientificName: "Ocimum basilicum",
            watering: "Frequent",
            wateringFrequency: WateringFrequency(unit: "days", value: "3"),
            sunlight: ["full sun"],
            maintenance: "Moderate",
            indoor: true,
            imageUrl: nil,
            careLevel: "Moderate",
            description:
                "Basil needs plenty of sunlight and regular watering.",
        ),
        PlantSpecies(
            speciesId: 4,
            commonName: "Tomato",
            scientificName: "Solanum lycopersicum",
            watering: "Average",
            wateringFrequency: WateringFrequency(unit: "days", value: "2"),
            sunlight: ["full sun"],
            maintenance: "Moderate",
            indoor: false,
            imageUrl: nil,
            careLevel: "Moderate",
            description:
                "Tomatoes need direct sunlight, regular watering, and support as they grow.",
        ),
        PlantSpecies(
            speciesId: 5,
            commonName: "Lavender",
            scientificName: "Lavandula angustifolia",
            watering: "Minimum",
            wateringFrequency: WateringFrequency(unit: "days", value: "10"),
            sunlight: ["full sun"],
            maintenance: "Low",
            indoor: false,
            imageUrl: nil,
            careLevel: "Easy",
            description:
                "Lavender prefers full sun and dry soil and benefits from pruning after flowering.",
        ),
        PlantSpecies(
            speciesId: 6,
            commonName: "Rosemary",
            scientificName: "Salvia rosmarinus",
            watering: "Minimum",
            wateringFrequency: WateringFrequency(unit: "days", value: "7"),
            sunlight: ["full sun"],
            maintenance: "Low",
            indoor: true,
            imageUrl: nil,
            careLevel: "Easy",
            description:
                "Rosemary prefers full sun and well-draining soil. Water after the soil dries.",
        )
    ]

    func searchPlants(matching query: String) async throws -> [PlantSpecies] {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else {
            return Self.samplePlants
        }
      
        return Self.samplePlants.filter {
            $0.commonName.localizedCaseInsensitiveContains(trimmedQuery)
            || $0.scientificName.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        guard let plant = Self.samplePlants.first(
            where: { $0.speciesId == id }
        ) else {
            throw LocalPlantCatalogError.plantNotFound
        }
        
        return plant
    }
}
