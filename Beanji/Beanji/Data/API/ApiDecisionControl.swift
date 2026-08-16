//
//  ApiDecisionControl.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 29.06.26.
//
//  MARK: ApiDecisionControl
//  Fallback mechanism for plant API calls.
//  The remote API must be configured explicitly.

struct ApiDecisionControl: PlantAPI {
    private let primaryAPI: PlantAPI
    private let fallbackAPI: PlantAPI

    init(
        primaryAPI: PlantAPI,
        fallbackAPI: PlantAPI = LocalPlantCatalog()
    ) {
        self.primaryAPI = primaryAPI
        self.fallbackAPI = fallbackAPI
    }

    func searchPlants(matching query: String) async throws -> [PlantSpecies] {
        do {
            let result = try await primaryAPI.searchPlants(matching: query)
            return result
        } catch {
            return try await fallbackAPI.searchPlants(matching: query)
        }
    }

    func searchPlants(matching query: String, page: Int, perPage: Int) async throws -> [PlantSpecies] {
        do {
            let result = try await primaryAPI.searchPlants(
                matching: query,
                page: page,
                perPage: perPage
            )
            return result
        } catch {
            return try await fallbackAPI.searchPlants(
                matching: query,
                page: page,
                perPage: perPage
            )
        }
    }

    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        do {
            return try await primaryAPI.getPlantDetail(id: id)
        } catch {
            return try await fallbackAPI.getPlantDetail(id: id)
        }
    }
}
