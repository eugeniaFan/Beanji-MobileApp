//
//  CatalogEnrichmentService.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 29.06.26.
//
//  Provides optional plant information from a remote data source.
//  Remote requests are only made when a caller explicitly starts them.

struct CatalogEnrichmentService: PlantSpeciesProvider {
    private let remoteProvider: PlantSpeciesProvider

    init(remoteProvider: PlantSpeciesProvider) {
        self.remoteProvider = remoteProvider
    }

    
    func searchPlants(matching query: String) async throws -> [PlantSpecies] {
        try await remoteProvider.searchPlants(matching: query)
    }

    func searchPlants(matching query: String, page: Int, perPage: Int) async throws -> [PlantSpecies] {
        try await remoteProvider.searchPlants(
            matching: query,
            page: page,
            perPage: perPage
        )
    }

    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        try await remoteProvider.getPlantDetail(id: id)
    }
}
