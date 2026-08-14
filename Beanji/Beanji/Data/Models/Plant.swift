//
//  Plant.swift
//  StudentProjekt
//
//  Created by Eugenia Fanenstiel on 10.06.26.
//
//  MARK: SwiftData Model: Plant
//  Describes a plant, which the user actually saved.

import Foundation
import SwiftData


@Model
class Plant: Identifiable{
    var id: UUID = UUID()
    
    var name: String
    var speciesName: String
    
    var lastWatered: Date
    var lastFertilized: Date
    
    var wateringIntervalDays: Int
    var fertilizingIntervalDays: Int
    
    var createdAt: Date
    var notes: String?
    
    var photoData: Data?
    var location: String? = nil
    
    @Relationship(inverse: \PlantSpeciesInfo.plant)     // One to one relation
    var speciesInfo: PlantSpeciesInfo? = nil
    
    
    init(name: String, speciesName: String,
         lastWatered: Date,
         lastFertilized: Date,
         wateringIntervalDays: Int,
         fertilizingIntervalDays: Int,
         imageName: String? = nil,
         createdAt: Date,
         notes: String? = nil,
         photoData: Data? = nil,
         location: String? = nil,
         speciesInfo: PlantSpeciesInfo? = nil
    ) {
        self.name = name
        self.speciesName = speciesName
        self.lastWatered = lastWatered
        self.lastFertilized = lastFertilized
        self.wateringIntervalDays = wateringIntervalDays
        self.fertilizingIntervalDays = fertilizingIntervalDays
        self.createdAt = createdAt
        self.notes = notes
        self.photoData = photoData
        self.location = location
        self.speciesInfo = speciesInfo
        
    }
}

//  MARK: - Shared watering schedule logic

//  Centralizes the "when is this plant due for watering" calculation so
//  ViewModels don't each reimplement the same date math.
extension Plant {

    // The next date this plant is due to be watered, based on `lastWatered` and `wateringIntervalDays`.
    func nextWateringDate(using calendar: Calendar = .current) -> Date {
        calendar.date(
            byAdding: .day,
            value: wateringIntervalDays,
            to: lastWatered
        ) ?? lastWatered
    }

    // Number of days from `referenceDate` until the plant's next watering is due.
    // A negative value means the plant is overdue by that many days.
    func daysUntilNextWatering(
        using calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> Int {
        let dueDay = calendar.startOfDay(for: nextWateringDate(using: calendar))
        let today = calendar.startOfDay(for: referenceDate)
        return calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0
    }
}
