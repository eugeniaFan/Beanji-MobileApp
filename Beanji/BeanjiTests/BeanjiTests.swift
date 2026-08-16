//
//  BeanjiTests.swift
//  BeanjiTests
//
//  Created by Eugenia Fanenstiel on 14.08.26.

import Foundation
import Testing
@testable import Beanji

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
    
    func searchPlants(
            matching query: String
        ) async throws -> [PlantSpecies] {
            let trimmedQuery = query.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !trimmedQuery.isEmpty else {
                return plants
            }

            return plants.filter { plant in
                plant.commonName.localizedCaseInsensitiveContains(
                    trimmedQuery
                )
                || plant.scientificName.localizedCaseInsensitiveContains(
                    trimmedQuery
                )
            }
        }

        func getPlantDetail(
            id: Int
        ) async throws -> PlantSpecies {
            guard let plant = plants.first(
                where: { $0.speciesId == id }
            ) else {
                throw LocalPlantCatalogError.plantNotFound
            }

            return plant
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

struct BeanjiTests {

    @Test
    @MainActor
    func clearingCatalogSearchShowsAllLocalPlantsAgain() async {
        let viewModel = AllPlantsViewModel(
            catalogService: TestPlantCatalog(),
            repository: MockPlantRepository()
        )
        viewModel.selectedPage = .allPlants
        await viewModel.loadInitialData()
        
        #expect(viewModel.filteredCatalogPlants.count == 3)
        
        
        viewModel.searchText = "Monstera"
        await viewModel.performApiSearch()
        #expect(viewModel.filteredCatalogPlants.count == 1)
        
        #expect(viewModel.filteredCatalogPlants.first?.commonName == "Swiss Cheese Plant")
    
        
        viewModel.searchText = ""
        await viewModel.handleSearchTextChanged()

        #expect(viewModel.filteredCatalogPlants.count == 3)
    }
    
    @Test func enrichmentRequestsRemoteDataOnlyAfterExpicitSearch() async throws {
        let remoteProvider = TrackingRemoteProvider()
        
        let service = await CatalogEnrichmentService(remoteProvider: remoteProvider)
        #expect(remoteProvider.searchCallCount == 0)
        
        let results = try await service.searchPlants(matching: "Monstera")
        #expect(remoteProvider.searchCallCount == 1)
        #expect(remoteProvider.lastSearchQuery == "Monstera")
        #expect(results.count == 1)
        #expect(results.first?.commonName == "Remote Monstera")
    }
}
