//
//  LocalPlantCatalogAPI.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 22.06.26.
//
//  Loads local data from JSON

import Foundation

enum LocalPlantCatalogError: LocalizedError {
    case fileNotFound
    case decodingError
    case plantNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "JSON File could not be found."
        case .decodingError:
            return "Failed to decode data from JSON file."
        case .plantNotFound:
            return "Requested plant could not be found in the local catalog."
        }
    }
}

struct LocalPlantCatalog: PlantSpeciesProvider {
    private let fileName = "houseplants"
    private let fileExtension = "json"

    // Searches local catalog by common or scientific name.
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

    // Loads and decodes the JSON file.
    private func getAllPlants() throws -> [PlantSpecies] {
        // Try the straightforward bundle lookup
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
            
            return try JSONDecoder().decode(
                [PlantSpecies].self,
                from: data
            )
        } catch {
            // If we get here, the file couldn't be found in the bundle.
            throw LocalPlantCatalogError.decodingError
        }
    }
        

    
    // Returns detailed plant info for a specific ID.
    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        let allPlants = try getAllPlants()

        guard let plant = allPlants.first(
            where: { $0.id == id }
        ) else {
            throw LocalPlantCatalogError.plantNotFound
        }
        
        return plant
    }

    
    // Searches the local catalog and returns one page of results.
    func searchPlants(
        matching query: String,
        page: Int,
        perPage: Int
    ) async throws -> [PlantSpecies] {
        guard page > 0, perPage > 0 else { return [] }
        
        // Filter by query
        let filteredPlants = try await searchPlants(matching: query)
    
        // Pagination
        let startIndex = (page - 1) * perPage
        guard startIndex < filteredPlants.count else { return [] }

        let endIndex = min(
            startIndex + perPage,
            filteredPlants.count
        )
        return Array(filteredPlants[startIndex..<endIndex])
    }
}
