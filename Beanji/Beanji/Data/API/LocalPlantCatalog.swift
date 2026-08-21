//
//  LocalPlantCatalog.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 22.06.26.
//
//  Loads bundled houseplant data from JSON.

import Foundation

enum LocalPlantCatalogError: LocalizedError {
    case fileNotFound
    case decodingError
    case invalidCatalog(String)
    case plantNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "JSON File could not be found."
        case .decodingError:
            return "Failed to decode data from JSON file."
        case .invalidCatalog(let reason):
            return "The local catalog is invalid: \(reason)"
        case .plantNotFound:
            return "Requested plant could not be found in the local catalog."
        }
    }
}

struct LocalPlantCatalog: PlantCatalogRepository {
    private let fileName = "houseplants"
    private let fileExtension = "json"

    func searchPlants(matching query: String) async throws -> [PlantSpecies] {
        let allPlants = try getAllPlants()
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else { return allPlants }

        return allPlants.filter { plant in
            plant.commonName.localizedCaseInsensitiveContains(trimmedQuery)
                || plant.scientificName.localizedCaseInsensitiveContains(
                    trimmedQuery
                )
        }
    }

    private func getAllPlants() throws -> [PlantSpecies] {
        guard let fileURL = Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension
        ) else {
            throw LocalPlantCatalogError.fileNotFound
        }
        
        do {
            let data = try Data(
                contentsOf: fileURL,
                options: .mappedIfSafe
            )
            
            let localPlants = try JSONDecoder().decode(
                [BundledPlantEntry].self,
                from: data
            )
            try BundledPlantEntry.validate(localPlants)
            return localPlants.map(\.plantSpecies)
        } catch let error as LocalCatalogValidationError {
            throw LocalPlantCatalogError.invalidCatalog(
                error.localizedDescription
            )
        } catch {
            throw LocalPlantCatalogError.decodingError
        }
    }
    
    
    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        let allPlants = try getAllPlants()

        guard let plant = allPlants.first(
            where: { $0.id == id }
        ) else {
            throw LocalPlantCatalogError.plantNotFound
        }
        
        return plant
    }
}
