//
//  LocalPlantCatalogAPI.swift
//  StudentProjekt
//
//  Created by Eugenia Fanenstiel on 22.06.26.
//
//  Mock implementation of the Perenual API.
//  Loads local data JSON


import Foundation

enum LocalPlantCatalogError: Error {
    case fileNotFound
    case decodingError
    case plantNotFound
}

struct LocalPlantCatalog: PlantAPI {
    private let fileName = "plantsCatalog"
    private let fileExtension = "json"
    
    
    // Searches local catalog by common or scientific name.
    func searchPlants(matching query: String) async throws -> [PlantSpecies] {
        let allPlants = try await getAllPlants()
        guard !query.isEmpty else { return allPlants }
        
        return allPlants.filter {
            $0.commonName.localizedCaseInsensitiveContains(query) == true ||
            $0.scientificName.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    
    // Loads and decodes the JSON file.
    func getAllPlants() async throws -> [PlantSpecies] {
        // Try the straightforward bundle lookup first
        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                return try JSONDecoder().decode([PlantSpecies].self, from: data)
            } catch {
                throw LocalPlantCatalogError.decodingError
            }
        }

        // Fallback: search the bundle resource folder recursively for the file.
        // This helps when the file wasn't added to Copy Bundle Resources in Xcode
        // or resides in a nested folder.
        if let resourceURL = Bundle.main.resourceURL {
            let fm = FileManager.default
            let enumerator = fm.enumerator(at: resourceURL, includingPropertiesForKeys: nil)
            while let element = enumerator?.nextObject() as? URL {
                if element.lastPathComponent == "\(fileName).\(fileExtension)" {
                    do {
                        let data = try Data(contentsOf: element, options: .mappedIfSafe)
                        return try JSONDecoder().decode([PlantSpecies].self, from: data)
                    } catch {
                        throw LocalPlantCatalogError.decodingError
                    }
                }
            }
        }

        // If we get here, the file couldn't be found in the bundle.
        throw LocalPlantCatalogError.fileNotFound
    }

    
    // Returns detailed plant info for a specific ID.
    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        let allPlants = try await getAllPlants()
        
        guard let plant = allPlants.first(where: { $0.id == id }) else {
            throw LocalPlantCatalogError.plantNotFound
        }
        return plant
    }
    
    func searchPlants(matching query: String, page: Int, perPage: Int) async throws -> [PlantSpecies] {
        let allPlants = try await getAllPlants()

        // Filter by query
        let filteredPlants: [PlantSpecies]
        if query.isEmpty {
            filteredPlants = allPlants
        } else {
            filteredPlants = allPlants.filter {
                $0.commonName.localizedCaseInsensitiveContains(query) ||
                $0.scientificName.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Pagination
        let start = (page - 1) * perPage
        guard start < filteredPlants.count else { return [] }
        
        let end = min(start + perPage, filteredPlants.count)
        return Array(filteredPlants[start..<end])
    }
}
