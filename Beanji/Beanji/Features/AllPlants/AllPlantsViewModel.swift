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
        case .myPlants: return "Meine Pflanzen"
        case .allPlants: return "Alle Pflanzen"
        }
    }
}

@Observable
@MainActor
final class AllPlantsViewModel {
    private let catalogService: PlantCatalogRepository
    private let repository: PlantRepository
    private let catalogPageSize = 40

    // MARK: - State
    var myPlants: [Plant] = []
    var catalogPlants: [PlantSpecies] = []
    var searchText = ""

    var showingAddPlant = false
    var selectedFilter = "Alle"
    var selectedPage: PlantListPage = .myPlants
    var plantToDelete: Plant?
    var isLoading = false
    var isCatalogLoading = false
    var errorMessage: String?
    var canLoadMoreCatalog = true

    let filters = ["Alle", "Drinnen", "Viel Licht", "Schatten"]
    private var catalogPage = 1
    private var isSearching = false
    
    init(catalogService: PlantCatalogRepository, repository: PlantRepository) {
        self.catalogService = catalogService
        self.repository = repository
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
        async let catalog: () = loadCatalogFromLocal(reset: true)
        _ = await (ownPlants, catalog)
    }

    func loadMyPlants() async {
        isLoading = true
        do {
            myPlants = try await repository.fetchAllPlants()
            errorMessage = nil
        } catch {
            errorMessage =
            "Fehler beim Laden aller Pflanzen: \(error.localizedDescription)"
        }
        isLoading = false
    }

    
    // Catalog search stays in memory; personal plant search queries persistence.
    func handleSearchTextChanged() async {
        if selectedPage == .myPlants {
            await loadMyPlantsFiltered()
            return
        }
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if query.isEmpty && !isSearching {
            if catalogPlants.isEmpty {
                await loadCatalogFromLocal(reset: true)
            }
        }
    }
    
    private func loadMyPlantsFiltered() async {
        isLoading = true
        do {
            let query = searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            
            myPlants = try await repository.fetchPlants(
                searchText: query.isEmpty ? nil : query,
                filter: selectedFilter == "Alle" ? nil : selectedFilter
            )
            errorMessage = nil
        } catch {
            errorMessage =
            "Fehler beim Laden der Pflanzen: \(error.localizedDescription)"
        }
        isLoading = false
    }

   
    // Pagination keeps larger future catalogs responsive.
    private func loadCatalogFromLocal(reset: Bool) async {
        if reset {
            catalogPage = 1
            catalogPlants = []
            canLoadMoreCatalog = true
            isSearching = false
        }

        guard canLoadMoreCatalog, !isCatalogLoading else { return }
        isCatalogLoading = true
        
        defer {
                isCatalogLoading = false
            }

        do {
            let pagePlants = try await catalogService.searchPlants(
                matching: "",
                page: catalogPage,
                perPage: catalogPageSize
            )

            if reset {
                catalogPlants = pagePlants
            } else {
                catalogPlants.append(contentsOf: pagePlants)
            }

            canLoadMoreCatalog = pagePlants.count == catalogPageSize
            if canLoadMoreCatalog {
                catalogPage += 1
            }

            errorMessage = nil
        } catch {
            errorMessage =
            "Fehler beim Laden des Pflanzenkatalogs: \(error.localizedDescription)"
        }
    }

    private func refreshCatalogPlants(_ plants: [PlantSpecies]) async -> [PlantSpecies] {
        var refreshedPlants: [PlantSpecies] = []

        for plant in plants {
            guard let refreshedPlant = try? await catalogService.getPlantDetail(id: plant.speciesId) else {
                refreshedPlants.append(plant)
                continue
            }

            refreshedPlants.append(merge(localPlant: plant, refreshedPlant: refreshedPlant))
        }

        return refreshedPlants
    }

    private func merge(localPlant: PlantSpecies, refreshedPlant: PlantSpecies) -> PlantSpecies {
        PlantSpecies(
            speciesId: localPlant.speciesId,
            commonName: refreshedPlant.commonName.isEmpty ? localPlant.commonName : refreshedPlant.commonName,
            scientificName: refreshedPlant.scientificName.isEmpty ? localPlant.scientificName : refreshedPlant.scientificName,
            watering: refreshedPlant.watering ?? localPlant.watering,
            wateringFrequency: refreshedPlant.wateringFrequency ?? localPlant.wateringFrequency,
            sunlight: refreshedPlant.sunlight ?? localPlant.sunlight,
            maintenance: refreshedPlant.maintenance ?? localPlant.maintenance,
            indoor: refreshedPlant.indoor ?? localPlant.indoor,
            imageUrl: refreshedPlant.imageUrl ?? localPlant.imageUrl,
            careLevel: refreshedPlant.careLevel ?? localPlant.careLevel,
            description: refreshedPlant.description ?? localPlant.description
        )
    }

    // Ensures catalog data is available when search is submitted.
    func performApiSearch() async {
        guard selectedPage == .allPlants else { return }
        isSearching = false
        
        // Preserve the full catalog because filteredCatalogPlants owns filtering.
        if catalogPlants.isEmpty {
            await loadCatalogFromLocal(reset: true)
        }
        errorMessage = nil
    }

    func loadNextCatalogPageIfNeeded(current species: PlantSpecies) async {
        guard selectedPage == .allPlants else { return }
        guard !isSearching else { return }
        guard let last = filteredCatalogPlants.last else { return }
        guard last.speciesId == species.speciesId else { return }
        await loadCatalogFromLocal(reset: false)
    }

    func addPlant(_ plant: Plant) async {
        do {
            try await repository.savePlant(plant)
            await loadMyPlants()
            errorMessage = nil
        } catch {
            errorMessage =
            "Fehler beim Speichern der Pflanze: \(error.localizedDescription)"
        }
    }
    
    func deletePlant(_ plant: Plant) async {
        isLoading = true
        do {
            try await repository.deletePlant(plant)
            myPlants.removeAll { $0.id == plant.id }
            errorMessage = nil
        } catch {
            errorMessage =
            "Fehler beim Löschen einer Pflanze: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func addSpeciesToMyPlants(_ species: PlantSpecies, userPlantName: String?) async {
        do {
            _ = try await repository.addSpeciesToMyPlants(
                from: species,
                userPlantName: userPlantName
            )
            await loadMyPlants()
            errorMessage = nil
        } catch {
            errorMessage =
            "Fehler beim Hinzufügen der Katalogpflanze: \(error.localizedDescription)"
        }
    }


    var filteredMyPlants: [Plant] {
        myPlants.filter { matchesFilter(plant: $0) }
    }

    var filteredCatalogPlants: [PlantSpecies] {
        let afterFilter = catalogPlants.filter { matchesFilter(species: $0) }
        if isSearching {
            return afterFilter
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return afterFilter }
        return afterFilter.filter {
            $0.commonName.localizedCaseInsensitiveContains(query)
            || $0.scientificName.localizedCaseInsensitiveContains(query)
        }
    }
    
    var searchResultCount: Int? {
        guard selectedPage == .allPlants, isSearching else { return nil }
        return filteredCatalogPlants.count
    }

    
    // MARK: - Filter Helpers

    private func matchesFilter(plant: Plant) -> Bool {
        switch selectedFilter {
        case "Alle":
            return true
        case "Drinnen":
            if let indoor = plant.speciesInfo?.indoor {
                return indoor
            }
            return plant.location?.localizedCaseInsensitiveContains("innen")
            == true
            || plant.location?.localizedCaseInsensitiveContains("indoor")
            == true
        case "Viel Licht":
            let sunlight = plant.speciesInfo?.sunlight ?? []
            return sunlight.contains {
                $0.localizedCaseInsensitiveContains("full")
            }
            || sunlight.contains {
                $0.localizedCaseInsensitiveContains("bright")
            }
        case "Schatten":
            let sunlight = plant.speciesInfo?.sunlight ?? []
            return sunlight.contains {
                $0.localizedCaseInsensitiveContains("shade")
            }
            || sunlight.contains {
                $0.localizedCaseInsensitiveContains("schatten")
            }
        default:
            return true
        }
    }
    private func matchesFilter(species: PlantSpecies) -> Bool {
        switch selectedFilter {
        case "Alle":
            return true
        case "Drinnen":
            return species.indoor == true
        case "Viel Licht":
            let sunlight = species.sunlight ?? []
            return sunlight.contains {
                $0.localizedCaseInsensitiveContains("full")
            }
            || sunlight.contains {
                $0.localizedCaseInsensitiveContains("bright")
            }
        case "Schatten":
            let sunlight = species.sunlight ?? []
            return sunlight.contains {
                $0.localizedCaseInsensitiveContains("shade")
            }
            || sunlight.contains {
                $0.localizedCaseInsensitiveContains("schatten")
            }
        default:
            return true
        }
    }
}

func nextWateringText(for plant: Plant) -> String {
    let days = plant.daysUntilNextWatering()

    if days <= 0 {
        return "Heute gießen"
    } else if days == 1 {
        return "Morgen"
    } else {
        return "In \(days) Tagen"
    }
}

func waterStatusColor(for plant: Plant) -> Color {
    plant.daysUntilNextWatering() <= 1 ? .orange : .blue
}
