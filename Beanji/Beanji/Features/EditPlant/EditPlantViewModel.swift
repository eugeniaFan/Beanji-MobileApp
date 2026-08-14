//
//  EditPlantViewModel.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 11.08.26.
//

import Foundation
import Observation

@Observable
@MainActor
final class EditPlantViewModel {
    var plant: Plant
    private let repository: PlantRepository

    var name: String
    var location: String
    var notes: String
    var wateringIntervalDays: Int
    var fertilizingIntervalDays: Int
    var isSaving = false
    var errorMessage: String?

    // Callback invoked after a successful update
    var onPlantUpdated: (() -> Void)?

    init(plant: Plant, repository: PlantRepository) {
        self.plant = plant
        self.repository = repository

        self.name = plant.name
        self.location = plant.location ?? ""
        self.notes = plant.notes ?? ""
        self.wateringIntervalDays = plant.wateringIntervalDays
        self.fertilizingIntervalDays = plant.fertilizingIntervalDays
    }
    
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        defer { isSaving = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        plant.name = trimmedName
        plant.location = trimmedLocation.isEmpty ? nil : trimmedLocation
        plant.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil : notes
        plant.wateringIntervalDays = wateringIntervalDays
        plant.fertilizingIntervalDays = fertilizingIntervalDays

        do {
            try await repository.updatePlant(plant)
            errorMessage = nil
           onPlantUpdated?()
            return true
        } catch {
            errorMessage = "Pflanze konnte nicht gespeichert werden."
            return false
        }
    }

    func saveChanges() async {
        _ = await save()
    }
}

