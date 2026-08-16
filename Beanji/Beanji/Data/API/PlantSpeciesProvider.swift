//
//  PlantSpeciesProvider.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 11.06.26.
//
//  Defines the shared read operations for plant species data.

import Foundation

protocol PlantSpeciesProvider {

    // Searches for plant species matching a query string
    func searchPlants(matching query: String) async throws -> [PlantSpecies]

    // Paginierte Suche (Prio 2): HTTP kann echte Seiten laden, lokale Quellen nutzen den Default unten.
    func searchPlants(matching query: String, page: Int, perPage: Int) async throws -> [PlantSpecies]

    // Fetches detailed information for a specific plant by ID.
    func getPlantDetail(id: Int) async throws -> PlantSpecies

}

extension PlantSpeciesProvider {
    func searchPlants(matching query: String, page: Int, perPage: Int) async throws -> [PlantSpecies] {
        let allPlants = try await searchPlants(matching: query)
        
        guard page > 0, perPage > 0 else { return [] }

        let startIndex = (page - 1) * perPage
        guard startIndex < allPlants.count else { return [] }

        let endIndex = min(startIndex + perPage, allPlants.count)
        return Array(allPlants[startIndex..<endIndex])
    }
}

// A catalog repository provides plant species used for browsing and search.
protocol PlantCatalogRepository: PlantSpeciesProvider {}
