//
//  BundledPlantEntry.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 21.08.26.
//
//  Defines and validates the Beanji-owned local catalog schema.

import Foundation

enum WateringNeed: String, Codable, Equatable {
    case low
    case moderate
    case high

    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .moderate:
            return "Moderate"
        case .high:
            return "High"
        }
    }
}

enum CareDifficulty: String, Codable, Equatable {
    case beginnerFriendly
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginnerFriendly:
            return "Beginner friendly"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        }
    }
}

enum LightRequirement: String, Codable, Hashable {
    case low
    case mediumIndirect
    case brightIndirect
    case direct

    var displayName: String {
        switch self {
        case .low:
            return "Low light"
        case .mediumIndirect:
            return "Medium indirect light"
        case .brightIndirect:
            return "Bright indirect light"
        case .direct:
            return "Direct light"
        }
    }
}

struct BundledPlantEntry: Decodable, Equatable {
    let id: Int
    let commonName: String
    let scientificName: String
    let wateringNeed: WateringNeed
    let wateringIntervalDays: Int
    let lightRequirements: [LightRequirement]
    let careDifficulty: CareDifficulty
    let isIndoor: Bool
    let imageAssetName: String?
    let description: String

    // This adapter keeps the new local schema isolated from legacy provider fields.
    var plantSpecies: PlantSpecies {
        PlantSpecies(
            speciesId: id,
            commonName: commonName,
            scientificName: scientificName,
            watering: wateringNeed.displayName,
            wateringFrequency: WateringFrequency(
                unit: "days",
                value: String(wateringIntervalDays)
            ),
            sunlight: lightRequirements.map(\.displayName),
            maintenance: nil,
            indoor: isIndoor,
            imageAssetName: imageAssetName,
            imageUrl: nil,
            careLevel: careDifficulty.displayName,
            description: description
        )
    }

    // Validate the complete collection so cross-entry conflicts are caught early.
    static func validate(_ plants: [BundledPlantEntry]) throws {
        guard !plants.isEmpty else {
            throw LocalCatalogValidationError.emptyCatalog
        }

        var usedIDs = Set<Int>()
        var usedScientificNames = Set<String>()

        for plant in plants {
            guard plant.id > 0 else {
                throw LocalCatalogValidationError.invalidID(plant.id)
            }
            guard usedIDs.insert(plant.id).inserted else {
                throw LocalCatalogValidationError.duplicateID(plant.id)
            }

            try validateRequiredText(
                plant.commonName,
                field: "commonName",
                plantID: plant.id
            )
            try validateRequiredText(
                plant.scientificName,
                field: "scientificName",
                plantID: plant.id
            )
            try validateRequiredText(
                plant.description,
                field: "description",
                plantID: plant.id
            )

            let normalizedScientificName = plant.scientificName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard usedScientificNames.insert(normalizedScientificName).inserted else {
                throw LocalCatalogValidationError.duplicateScientificName(
                    plant.scientificName
                )
            }

            guard (1...30).contains(plant.wateringIntervalDays) else {
                throw LocalCatalogValidationError.invalidWateringInterval(
                    plantID: plant.id,
                    value: plant.wateringIntervalDays
                )
            }
            guard !plant.lightRequirements.isEmpty else {
                throw LocalCatalogValidationError.missingLightRequirement(
                    plantID: plant.id
                )
            }
            guard Set(plant.lightRequirements).count
                    == plant.lightRequirements.count
            else {
                throw LocalCatalogValidationError.duplicateLightRequirement(
                    plantID: plant.id
                )
            }

            if let imageAssetName = plant.imageAssetName {
                try validateRequiredText(
                    imageAssetName,
                    field: "imageAssetName",
                    plantID: plant.id
                )
            }
        }
    }

    private static func validateRequiredText(
        _ value: String,
        field: String,
        plantID: Int
    ) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LocalCatalogValidationError.emptyRequiredValue(
                plantID: plantID,
                field: field
            )
        }
    }
}

enum LocalCatalogValidationError: LocalizedError, Equatable {
    case emptyCatalog
    case invalidID(Int)
    case duplicateID(Int)
    case duplicateScientificName(String)
    case emptyRequiredValue(plantID: Int, field: String)
    case invalidWateringInterval(plantID: Int, value: Int)
    case missingLightRequirement(plantID: Int)
    case duplicateLightRequirement(plantID: Int)

    var errorDescription: String? {
        switch self {
        case .emptyCatalog:
            return "The local catalog must contain at least one plant."
        case .invalidID(let id):
            return "Catalog plant ID \(id) must be greater than zero."
        case .duplicateID(let id):
            return "Catalog plant ID \(id) is duplicated."
        case .duplicateScientificName(let name):
            return "Scientific name \(name) is duplicated."
        case .emptyRequiredValue(let plantID, let field):
            return "Catalog plant \(plantID) has an empty \(field) value."
        case .invalidWateringInterval(let plantID, let value):
            return "Catalog plant \(plantID) has invalid watering interval \(value)."
        case .missingLightRequirement(let plantID):
            return "Catalog plant \(plantID) needs at least one light requirement."
        case .duplicateLightRequirement(let plantID):
            return "Catalog plant \(plantID) contains duplicate light requirements."
        }
    }
}
