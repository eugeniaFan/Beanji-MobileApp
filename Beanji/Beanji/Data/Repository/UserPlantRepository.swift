//
//  UserPlantRepository.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 24.06.26.
//
//  Defines persistence operations for the user's plants.

import Foundation

enum UserPlantRepositoryError: LocalizedError {
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case updateFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Could not load saved plants."
        case .saveFailed:
            return "Could not save the plant."
        case .deleteFailed:
            return "Could not delete the plant."
        case .updateFailed:
            return "Could not update the plant."
        }
    }
}

@MainActor
protocol UserPlantRepository {
    func fetchAllPlants() throws -> [Plant]

    func savePlant(_ plant: Plant) throws
    
    func addSpeciesToMyPlants(
        from species: PlantSpecies,
        userPlantName: String?
    ) async throws -> Plant

    func deletePlant(_ plant: Plant) throws
    func updatePlant(_ plant: Plant) throws

    func refreshPlantSpeciesInfo(
        for plant: Plant,
        using provider: PlantSpeciesProvider
    ) async throws
}
