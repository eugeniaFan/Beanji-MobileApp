//
//  AddPlantViewModel.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 20.08.26.
//

import Foundation
import Observation

@Observable
@MainActor
final class AddPlantViewModel {
    private let repository: UserPlantRepository
    private let now: () -> Date

    var name = ""
    var speciesName = ""
    var location = ""
    var notes = ""
    var lastWatered: Date
    var lastFertilized: Date
    var wateringIntervalDays = 7
    var fertilizingIntervalDays = 30
    var errorMessage: String?
    var onPlantSaved: (() -> Void)?

    init(
        repository: UserPlantRepository,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now

        let initialDate = now()
        lastWatered = initialDate
        lastFertilized = initialDate
    }

    var canSave: Bool {
        !trimmedName.isEmpty && !trimmedSpeciesName.isEmpty
    }

    func save() -> Bool {
        guard canSave else {
            errorMessage = String(
                localized: "Plant name and species are required."
            )
            return false
        }

        let plant = Plant(
            name: trimmedName,
            speciesName: trimmedSpeciesName,
            lastWatered: lastWatered,
            lastFertilized: lastFertilized,
            wateringIntervalDays: wateringIntervalDays,
            fertilizingIntervalDays: fertilizingIntervalDays,
            createdAt: now(),
            notes: optionalText(notes),
            location: optionalText(location)
        )

        do {
            try repository.savePlant(plant)
            errorMessage = nil
            onPlantSaved?()
            return true
        } catch {
            errorMessage = String(localized: "The plant could not be saved.")
            return false
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedSpeciesName: String {
        speciesName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Stores empty optional fields as nil so manual plants match repository-created plants.
    private func optionalText(_ value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
