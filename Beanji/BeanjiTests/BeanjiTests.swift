//
//  BeanjiTests.swift
//  BeanjiTests
//
//  Created by Eugenia Fanenstiel on 14.08.26.

import Foundation
import Testing
@testable import Beanji


struct BeanjiTests {

    @Test
    @MainActor
    func clearingCatalogSearchShowsAllLocalPlantsAgain() async {
        let viewModel = AllPlantsViewModel(
            catalogService: TestPlantCatalog(),
            repository: InMemoryUserPlantRepository()
        )
        viewModel.selectedPage = .allPlants
        await viewModel.loadInitialData()
        
        let initialPlantCount = viewModel.filteredCatalogPlants.count
        #expect(initialPlantCount == 3)
        
        
        viewModel.searchText = "Monstera"
        await viewModel.performApiSearch()

        let searchResultCount = viewModel.filteredCatalogPlants.count
        let firstSearchResultName = viewModel.filteredCatalogPlants.first?.commonName
        
        #expect(searchResultCount == 1)
        #expect(firstSearchResultName == "Swiss Cheese Plant")
    
        viewModel.searchText = ""
        await viewModel.handleSearchTextChanged()

        let restoredPlantCount = viewModel.filteredCatalogPlants.count
        
        #expect(restoredPlantCount == 3)
    }
    
    @Test
    @MainActor
    func enrichmentRequestsRemoteDataOnlyAfterExplicitSearch() async throws {
        let remoteProvider = TrackingRemoteProvider()
        
        let service = CatalogEnrichmentService(remoteProvider: remoteProvider)
        let initialSearchCallCount = remoteProvider.searchCallCount
        #expect(initialSearchCallCount == 0)
        
        let results = try await service.searchPlants(matching: "Monstera")
        let finalSearchCallCount = remoteProvider.searchCallCount

        let receivedSearchQuery = remoteProvider.lastSearchQuery

        let remoteResultCount = results.count

        let firstRemoteResultName = results.first?.commonName

        #expect(finalSearchCallCount == 1)
        #expect(receivedSearchQuery == "Monstera")
        #expect(remoteResultCount == 1)
        #expect(firstRemoteResultName == "Remote Monstera")
    }
}

private struct TestPlantCatalog: PlantCatalogRepository {
    private let plants = [
        makePlantSpecies(
            id: 1,
            commonName: "Swiss Cheese Plant",
            scientificName: "Monstera deliciosa"
        ),
        makePlantSpecies(
            id: 2,
            commonName: "Snake Plant",
            scientificName: "Dracaena trifasciata"
        ),
        makePlantSpecies(
            id: 3,
            commonName: "Golden Pothos",
            scientificName: "Epipremnum aureum"
        ),
    ]
    
    func searchPlants(matching query: String) async throws -> [PlantSpecies] {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else {
            return plants
        }

        return plants.filter { plant in
            plant.commonName.localizedCaseInsensitiveContains(trimmedQuery)
            || plant.scientificName.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        guard let plant = plants.first(
            where: { $0.speciesId == id }
        ) else {
            throw LocalPlantCatalogError.plantNotFound
        }
        return plant
    }
}

private final class TrackingRemoteProvider: PlantSpeciesProvider {
    private(set) var searchCallCount = 0
    private(set) var lastSearchQuery: String?

    func searchPlants(
        matching query: String
    ) async throws -> [PlantSpecies] {
        searchCallCount += 1
        lastSearchQuery = query

        return [
            makePlantSpecies(
                id: 100,
                commonName: "Remote Monstera",
                scientificName: "Monstera deliciosa"
            )
        ]
    }

    func getPlantDetail(
        id: Int
    ) async throws -> PlantSpecies {
        makePlantSpecies(
            id: id,
            commonName: "Remote Monstera",
            scientificName: "Monstera deliciosa"
        )
    }
}

private func makePlantSpecies(
    id: Int,
    commonName: String,
    scientificName: String
) -> PlantSpecies {
    PlantSpecies(
        speciesId: id,
        commonName: commonName,
        scientificName: scientificName,
        watering: nil,
        wateringFrequency: nil,
        sunlight: nil,
        maintenance: nil,
        indoor: true,
        imageUrl: nil,
        careLevel: nil,
        description: nil
    )
}
