//
//  Plant.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 10.06.26.
//
//  Stores a plant saved by the user.

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
    
    // Saved plants reference shared species metadata.
    @Relationship(inverse: \PlantSpeciesInfo.plant)
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
