//
//  PlantSpecies.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 22.06.26.
//
//  Represents species data shared by local and optional remote providers.

import Foundation


struct PlantSpecies: Codable, Identifiable {
    var id: Int { speciesId }
    let speciesId: Int     
    let commonName: String
    let scientificName: String
    let watering: String?
    let wateringFrequency: WateringFrequency?
    let sunlight: [String]?
    let maintenance: String?
    let indoor: Bool?
    let imageAssetName: String?
    let imageUrl: String?
    let careLevel: String?
    let description: String?

    init(
        speciesId: Int,
        commonName: String,
        scientificName: String,
        watering: String?,
        wateringFrequency: WateringFrequency?,
        sunlight: [String]?,
        maintenance: String?,
        indoor: Bool?,
        imageAssetName: String? = nil,
        imageUrl: String?,
        careLevel: String?,
        description: String?
    ) {
        self.speciesId = speciesId
        self.commonName = commonName
        self.scientificName = scientificName
        self.watering = watering
        self.wateringFrequency = wateringFrequency
        self.sunlight = sunlight
        self.maintenance = maintenance
        self.indoor = indoor
        self.imageAssetName = imageAssetName
        self.imageUrl = imageUrl
        self.careLevel = careLevel
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case speciesId = "id"
        case commonName
        case scientificName
        case watering
        case wateringFrequency
        case sunlight
        case maintenance
        case indoor
        case imageAssetName
        case imageUrl
        case careLevel
        case description
    }
}

struct WateringFrequency: Codable {
    let unit: String
    let value: String
}
