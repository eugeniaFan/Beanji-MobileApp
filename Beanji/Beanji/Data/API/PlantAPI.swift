//
//  PlantAPI.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 11.06.26.
//
//  MARK: Plant Protocol
//  Defines the contract for plant data sources (local, HTTP, or mock).

import Foundation

protocol PlantAPI {

    // Searches for plant species matching a query string
    func searchPlants(matching query: String) async throws -> [PlantSpecies]

    // Paginierte Suche (Prio 2): HTTP kann echte Seiten laden, lokale Quellen nutzen den Default unten.
    func searchPlants(matching query: String, page: Int, perPage: Int) async throws -> [PlantSpecies]

    // Fetches detailed information for a specific plant by ID.
    func getPlantDetail(id: Int) async throws -> PlantSpecies

}

extension PlantAPI {
    func searchPlants(matching query: String, page: Int, perPage: Int) async throws -> [PlantSpecies] {
        let all = try await searchPlants(matching: query)
        guard page > 0, perPage > 0 else { return all }

        let start = (page - 1) * perPage
        guard start < all.count else { return [] }

        let end = min(start + perPage, all.count)
        return Array(all[start..<end])
    }
}
