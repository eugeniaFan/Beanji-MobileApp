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
            description: "Aloe Vera ist eine pflegeleichte Sukkulente, die wenig Wasser braucht.",
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
            description: "Die Monstera mag indirektes Licht und große, gefensterte Blätter.",
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
            description: "Basilikum braucht viel Sonne und regelmäßiges Gießen.",
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
            description: "Tomaten brauchen mindestens 6-8 Stunden direkte Sonne, regelmäßiges Gießen und eine Rankhilfe.",
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
            description: "Lavendel liebt volle Sonne und trockenen Boden. Nach der Blüte zurückschneiden.",
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
            description: "Rosmarin mag volle Sonne und gut durchlässigen Boden. Erst gießen, wenn die Erde trocken ist.",
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
