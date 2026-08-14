//
//  PlantRepository.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 24.06.26.
//
//  MARK: Protocol for real persistent user plant data

import Foundation

@MainActor
protocol PlantRepository {
    func fetchAllPlants() async throws -> [Plant]
    func fetchPlants(searchText: String?, filter: String?) async throws -> [Plant]
    
    func savePlant(_ plant: Plant) async throws
    func addSpeciesToMyPlants(from species: PlantSpecies, userPlantName: String?) async throws -> Plant
    
    func deletePlant(_ plant: Plant) async throws
    func updatePlant(_ plant: Plant) async throws
    
    func refreshPlantSpeciesInfo(for plant: Plant, plantAPI: PlantAPI) async throws
}
