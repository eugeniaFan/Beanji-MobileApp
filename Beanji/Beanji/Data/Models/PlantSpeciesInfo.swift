//
//  PlantSpeciesInfo.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 26.06.26.
//
//  Stores reusable species details for a saved plant.

import SwiftData
import Foundation


@Model
final class PlantSpeciesInfo: Identifiable, Hashable {
    @Attribute(.unique) var speciesInfoId: Int
    var commonName: String
    var scientificName: String
    var watering: String?
    var wateringFrequency: WateringFrequency?
    var sunlight: [String]?
    var maintenance: String?
    var indoor: Bool?
    var imageUrl: String?
    var careLevel: String?
    var speciesDescription: String?
    var lastRefreshAt = Date()
    
    @Relationship
    var plant: [Plant] = []
    
    init(from species: PlantSpecies){
        self.speciesInfoId = species.speciesId
        self.commonName = species.commonName
        self.scientificName = species.scientificName
        self.watering = species.watering
        self.wateringFrequency = species.wateringFrequency
        self.sunlight = species.sunlight
        self.maintenance = species.maintenance
        self.indoor = species.indoor
        self.imageUrl = species.imageUrl
        self.careLevel = species.careLevel
        self.speciesDescription = species.description
        self.lastRefreshAt = Date()
    }
    
    func update(from species: PlantSpecies) {
        commonName = species.commonName
        scientificName = species.scientificName
        watering = species.watering
        wateringFrequency = species.wateringFrequency
        sunlight = species.sunlight
        maintenance = species.maintenance
        indoor = species.indoor
        imageUrl = species.imageUrl
        careLevel = species.careLevel
        speciesDescription = species.description
        lastRefreshAt = Date()  
    }
}
