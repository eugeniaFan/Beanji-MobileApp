//
//  PlantDetailViewModel.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 26.06.26.
//

import Foundation
import Observation

enum PlantDetailMode {
    case editablePlant(Plant)
    case readOnlySpecies(PlantSpecies)
}

@Observable
@MainActor
final class PlantDetailViewModel {
    private let repository: UserPlantRepository
    private let plantSpeciesProvider: PlantSpeciesProvider?
    private let calendar: Calendar

    let mode: PlantDetailMode
    
    // MARK: - Callbacks
    
    var onPlantDeleted: (() -> Void)?
    var onDidAddToMyPlants: (() -> Void)?
    var onEditRequested: ((Plant) -> Void)?
    var onPlantUpdated: (() -> Void)?
    var showingEditSheet: Bool = false {
        didSet {
            if showingEditSheet && editViewModel == nil {
                editViewModel = makeEditPlantViewModel()
            }
        }
    }
    var editViewModel: EditPlantViewModel?
    var showingDeleteAlert: Bool = false
    var showingAddToMyPlantsAlert: Bool = false
    var errorMessage: String?
    var pendingCustomName: String = ""
    var didFinishAddToMyPlants: Bool = false
    var isLoading: Bool = false

    private var enrichedSpecies: PlantSpecies?

    init(
        plant: Plant,
        repository: UserPlantRepository,
        plantSpeciesProvider: PlantSpeciesProvider?,
        calendar: Calendar = .current
    ) {
        self.mode = .editablePlant(plant)
        self.repository = repository
        self.plantSpeciesProvider = plantSpeciesProvider
        self.calendar = calendar
    }

    init(
        species: PlantSpecies,
        repository: UserPlantRepository,
        plantSpeciesProvider: PlantSpeciesProvider? = nil,
        calendar: Calendar = .current
    ) {
        self.mode = .readOnlySpecies(species)
        self.repository = repository
        self.plantSpeciesProvider = plantSpeciesProvider
        self.calendar = calendar
    }

    func makeEditPlantViewModel() -> EditPlantViewModel? {
        guard let plant = editablePlant else { return nil }
        let editViewModel = EditPlantViewModel(plant: plant, repository: repository)
        editViewModel.onPlantUpdated = { [weak self] in
            self?.onPlantUpdated?()
        }
        return editViewModel
    }

    // MARK: - Base Data

    var editablePlant: Plant? {
        if case .editablePlant(let plant) = mode {
            return plant
        }
        return nil
    }

    var species: PlantSpecies {
        switch mode {
        case .editablePlant(let plant):
            return PlantSpecies(
                speciesId: plant.speciesInfo?.speciesInfoId ?? -1,
                commonName: plant.speciesInfo?.commonName ?? plant.name,
                scientificName: plant.speciesInfo?.scientificName
                    ?? plant.speciesName,
                watering: plant.speciesInfo?.watering,
                wateringFrequency: plant.speciesInfo?.wateringFrequency,
                sunlight: plant.speciesInfo?.sunlight,
                maintenance: plant.speciesInfo?.maintenance,
                indoor: plant.speciesInfo?.indoor,
                imageUrl: plant.speciesInfo?.imageUrl,
                careLevel: plant.speciesInfo?.careLevel,
                description: plant.speciesInfo?.speciesDescription,
            )
        case .readOnlySpecies(let baseSpecies):
            return enrichedSpecies ?? baseSpecies
        }
    }

    var titleText: String {
        switch mode {
        case .editablePlant(let plant):
            return plant.name
        case .readOnlySpecies(let species):
            return species.commonName
        }
    }

    var subtitleText: String {
        switch mode {
        case .editablePlant(let plant):
            return plant.speciesName
        case .readOnlySpecies(let species):
            return species.scientificName
        }
    }

        var notesText: String? {
            guard let plant = editablePlant else { return nil }
            return plant.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

    var locationText: String? {
        guard let plant = editablePlant else { return nil }
        let trimmed = plant.location?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }
    
    var descriptionText: String? {
        let trimmed = species.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    // MARK: - Ideal Conditions

    var wateringConditionText: String {
        if let plant = editablePlant {
            return "Alle \(plant.wateringIntervalDays) Tage"
        }
        if let frequency = species.wateringFrequency {
            return "Alle \(cleaned(frequency.value)) Tage"
        }
        return species.watering ?? "Unbekannt"
    }

    var fertilizingConditionText: String {
        if let plant = editablePlant {
            return "Alle \(plant.fertilizingIntervalDays) Tage"
        }
    
        return "Unbekannt"
    }

    var sunlightConditionText: String {
        guard let sunlight = species.sunlight, !sunlight.isEmpty else {
            return "Unbekannt"
        }
        return sunlight.joined(separator: ", ")
    }

    var careConditionText: String {
        species.careLevel ?? species.maintenance ?? "Unbekannt"
    }

    private func cleaned(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // MARK: - Care Plan
    
    // Catalog species have no personal watering history.

    var hasCarePlan: Bool {
        editablePlant != nil
    }
    var nextWateringDueText: String? {
        guard let plant = editablePlant else { return nil }
        let dueDate = plant.nextWateringDate(using: calendar)
        let days = plant.daysUntilNextWatering(using: calendar)
        return CareDueTextFormatter.text(daysUntilDue: days, dueDate: dueDate)
    }

    var wateringIntervalPlanText: String? {
        guard let plant = editablePlant else { return nil }
        return "Alle \(plant.wateringIntervalDays) Tage"
    }

    // MARK: - Permissions
    var canEdit: Bool {
        if case .editablePlant = mode { return true }
        return false
    }

    var canDelete: Bool { canEdit }
    
    var canAddToMyPlants: Bool {
        if case .readOnlySpecies = mode { return true }
        return false
    }

    // MARK: - Actions

    func loadFullDetail() async {
        guard case .readOnlySpecies(let baseSpecies) = mode else { return }
        guard let plantSpeciesProvider else { return }
        isLoading = true
        do {
            enrichedSpecies = try await plantSpeciesProvider.getPlantDetail(id: baseSpecies.speciesId)
            errorMessage = nil
        } catch {
            errorMessage = "Detailinformationen konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func deletePlant() async -> Bool {
        guard case .editablePlant(let plant) = mode else { return false }
        do {
            try await repository.deletePlant(plant)
            onPlantDeleted?()
            return true
        }
        catch {
            errorMessage = "Pflanze konnte nicht gelöscht werden."
            return false
        }
    }

    func addCurrentSpeciesToMyPlants(userPlantName: String?) async {
        guard case .readOnlySpecies = mode else { return }
        didFinishAddToMyPlants = false

        do {
            _ = try await repository.addSpeciesToMyPlants(
                from: species,
                userPlantName: userPlantName
            )
            didFinishAddToMyPlants = true
            onDidAddToMyPlants?()
            errorMessage = nil
        }
        catch {
            errorMessage = "Pflanze konnte nicht hinzugefügt werden."
        }
    }

    var lastWateredText: String? {
        guard let plant = editablePlant else { return nil }

        let days =
            Calendar.current
            .dateComponents(
                [.day],
                from: plant.lastWatered,
                to: Date()
            )
            .day ?? 0

        if days == 0 { return "Heute" }
        if days == 1 { return "Gestern" }
        return "Vor \(days) Tagen"
    }

    var sunlightText: String {
        guard let sunlight = species.sunlight, !sunlight.isEmpty else {
            return "Unbekannt"
        }
        return sunlight.joined(separator: ", ")
    }

    var wateringInfoText: String {
        if let lastWateredText {
            return lastWateredText
        }
        if let watering = species.watering,
            !watering.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return watering
        }
        if let intervalText {
            return intervalText
        }
        return "Unbekannt"
    }

    var intervalText: String? {
        if let plant = editablePlant {
            return "\(plant.wateringIntervalDays) Tage"
        }

        if let frequency = species.wateringFrequency {
            return "\(frequency.value) \(frequency.unit)"
        }

        return nil
    }

    var canRefreshSpeciesInfo: Bool {
        guard case .editablePlant(let plant) = mode else { return false }
        return plant.speciesInfo != nil
    }

    func updatePlant(
        name: String,
        location: String,
        notes: String,
        wateringIntervalDays: Int,
        fertilizingIntervalDays: Int
    ) async {
        guard case .editablePlant(let plant) = mode else { return }
        plant.name = name
        plant.location =
            location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil : location
        plant.notes =
            notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil : notes
        plant.wateringIntervalDays = wateringIntervalDays
        plant.fertilizingIntervalDays = fertilizingIntervalDays

        do {
            try await repository.updatePlant(plant)
        }
        catch {
            errorMessage = "Pflanze konnte nicht aktualisiert werden."
        }
    }

}
