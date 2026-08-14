//
//  PlantSpeciesInfo.swift
//  StudentProjekt
//
//  Created by Eugenia Fanenstiel on 26.06.26.
//
// MARK: SwiftData Model: PlantSpeciesInfo 
// is used to store the plant species information in the local database using SwiftData. It is linked to the Plant model via a relationship.
// the information will be shown in the detail view of the plant, and it can be refreshed from the API if needed.

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
    
    //  Update the PlantSpeciesInfo with new data from a PlantSpecies instance
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
