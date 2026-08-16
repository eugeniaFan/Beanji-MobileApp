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
    let imageUrl: String?
    let careLevel: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case speciesId = "id"
        case commonName
        case scientificName
        case watering
        case wateringFrequency
        case sunlight
        case maintenance
        case indoor
        case imageUrl
        case careLevel
        case description
    }
}

struct WateringFrequency: Codable {
    let unit: String
    let value: String
}
