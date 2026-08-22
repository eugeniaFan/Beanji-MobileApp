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
    private let repository: UserPlantRepository

    var name: String
    var location: String
    var notes: String
    var wateringIntervalDays: Int
    var fertilizingIntervalDays: Int
    var errorMessage: String?

    var onPlantUpdated: (() -> Void)?

    init(plant: Plant, repository: UserPlantRepository) {
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

    func save() -> Bool {
        guard canSave else { return false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedNotes = notes.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        plant.name = trimmedName
        plant.location = trimmedLocation.isEmpty ? nil : trimmedLocation
        plant.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        plant.wateringIntervalDays = wateringIntervalDays
        plant.fertilizingIntervalDays = fertilizingIntervalDays

        do {
            try repository.updatePlant(plant)
            errorMessage = nil
            onPlantUpdated?()
            return true
        } catch {
            errorMessage = String(localized: "The plant could not be saved.")
            return false
        }
    }
}
