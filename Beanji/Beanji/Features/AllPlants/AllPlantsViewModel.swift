//
//  AllPlantsViewModel.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 23.06.26.
//

import Foundation
import Observation
import SwiftUI

enum PlantListPage: Int, CaseIterable, Identifiable, Hashable {
    case myPlants = 0
    case allPlants = 1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .myPlants: return "My Plants"
        case .allPlants: return "All Plants"
        }
    }
}

@Observable
@MainActor
final class AllPlantsViewModel {
    private let catalogService: PlantCatalogRepository
    private let repository: UserPlantRepository

    // MARK: - State
    var myPlants: [Plant] = []
    var catalogPlants: [PlantSpecies] = []
    var searchText = ""

    var selectedFilter = "All"
    var selectedPage: PlantListPage = .myPlants
    var plantToDelete: Plant?
    
    var isLoading = false
    var isCatalogLoading = false
    var errorMessage: String?

    let filters = ["All", "Indoor", "Bright light", "Shade"]

    init(
        catalogService: PlantCatalogRepository,
        repository: UserPlantRepository
    ) {
        self.catalogService = catalogService
        self.repository = repository
    }

    // Connects a successful manual save to the existing My Plants reload path.
    func makeAddPlantViewModel() -> AddPlantViewModel {
        let addPlantViewModel = AddPlantViewModel(
            repository: repository
        )
        addPlantViewModel.onPlantSaved = { [weak self] in
            Task {
                await self?.loadMyPlants()
            }
        }
        return addPlantViewModel
    }

    
    func makeDetailViewModel(
        for plant: Plant,
        onPlantDeleted: (() -> Void)? = nil
    ) -> PlantDetailViewModel {
        let detailViewModel = PlantDetailViewModel(
            plant: plant,
            repository: repository,
            plantSpeciesProvider: catalogService
        )
        detailViewModel.onPlantDeleted = onPlantDeleted
        detailViewModel.onPlantUpdated = { [weak self] in
            Task { await self?.loadMyPlants() }
        }

        return detailViewModel
    }

    
    func makeReadOnlySpeciesDetailViewModel(for species: PlantSpecies)
        -> PlantDetailViewModel
    {
        let viewModel = PlantDetailViewModel(
            species: species,
            repository: repository,
            plantSpeciesProvider: catalogService
        )
        viewModel.onDidAddToMyPlants = { [weak self] in
            Task { await self?.loadMyPlants() }
        }
        return viewModel
    }

    
    func loadInitialData() async {
        async let ownPlants: () = loadMyPlants()
        async let catalog: () = loadCatalog()
        
        _ = await (ownPlants, catalog)
    }

    
    func loadMyPlants() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            myPlants = try repository.fetchAllPlants()
            errorMessage = nil
        } catch {
            errorMessage =
                "Could not load saved plants: \(error.localizedDescription)"
        }
    }
    
    
    private func loadCatalog() async {
        guard !isCatalogLoading else { return }

        isCatalogLoading = true
        
        defer { isCatalogLoading = false }

        do {
            catalogPlants = try await catalogService.searchPlants(
                matching: ""
            )
            errorMessage = nil
        } catch {
            errorMessage =
                "Could not load the plant catalog: \(error.localizedDescription)"
        }
    }
    

    func deletePlant(_ plant: Plant) async {
        isLoading = true
        do {
            try repository.deletePlant(plant)
            myPlants.removeAll { $0.id == plant.id }
            errorMessage = nil
        } catch {
            errorMessage =
                "Could not delete the plant: \(error.localizedDescription)"
        }
        isLoading = false
    }

    
    var filteredMyPlants: [Plant] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return myPlants.filter { plant in
            guard matchesFilter(plant: plant) else {
                return false
            }

            guard !query.isEmpty else {
                return true
            }

            return plant.name.localizedCaseInsensitiveContains(query)
                || plant.speciesName.localizedCaseInsensitiveContains(query)
        }
    }

    var filteredCatalogPlants: [PlantSpecies] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return catalogPlants.filter { species in
            guard matchesFilter(species: species) else {
                return false
            }
            
            guard !query.isEmpty else {
                return true
            }
            
            return species.commonName.localizedCaseInsensitiveContains(query)
                || species.scientificName.localizedCaseInsensitiveContains(query)
        }
    }


    // MARK: - Filter Helpers

    private func matchesFilter(plant: Plant) -> Bool {
        switch selectedFilter {
        case "All":
            return true
        case "Indoor":
            if let indoor = plant.speciesInfo?.indoor {
                return indoor
            }
            return plant.location?.localizedCaseInsensitiveContains("indoor")
                == true
        case "Bright light":
            let sunlight = plant.speciesInfo?.sunlight ?? []
            return sunlight.contains {
                $0.localizedCaseInsensitiveContains("full")
            }
                || sunlight.contains {
                    $0.localizedCaseInsensitiveContains("bright")
                }
        case "Shade":
            let sunlight = plant.speciesInfo?.sunlight ?? []
            return sunlight.contains {
                $0.localizedCaseInsensitiveContains("shade")
            }
        default:
            return true
        }
    }
    
    private func matchesFilter(species: PlantSpecies) -> Bool {
        switch selectedFilter {
        case "All":
            return true
        case "Indoor":
            return species.indoor == true
        case "Bright light":
            let sunlight = species.sunlight ?? []
            return sunlight.contains {
                $0.localizedCaseInsensitiveContains("full")
            }
                || sunlight.contains {
                    $0.localizedCaseInsensitiveContains("bright")
                }
        case "Shade":
            let sunlight = species.sunlight ?? []
            return sunlight.contains {
                $0.localizedCaseInsensitiveContains("shade")
            }
        default:
            return true
        }
    }
}

func nextWateringText(for plant: Plant) -> String {
    let days = plant.daysUntilNextWatering()

    if days <= 0 {
        return "Water today"
    } else if days == 1 {
        return "Tomorrow"
    } else {
        return "In \(days) days"
    }
}

func waterStatusColor(for plant: Plant) -> Color {
    plant.daysUntilNextWatering() <= 1 ? .orange : .blue
}
