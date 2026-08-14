//
//  HttpPlantAPI.swift
//  StudentProjekt
//
//  Created by Eugenia Fanenstiel on 16.06.26.
//
//  MARK: Calls Perenual API to fetch plant data and details

import Foundation

enum ApiError: Error {
    case invalidUrl
    case encodingError
    case serverError
    case decodingError
    case noData
}

struct HttpPlantAPI: PlantAPI {
    
    private static let baseUrl = "https://perenual.com/api/v2"
    private static let fallbackBaseUrl = "https://perenual.com/api"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // DTOs mirror the JSON format of the Perenual API
    private struct SpeciesListResponse: Codable {
        let data: [SpeciesListItem]
    }
    
    private struct SpeciesListItem: Codable {
        let id: Int
        let commonName: String
        let scientificName: [String]
        let defaultImage: PlantImageDTO?
        
        enum CodingKeys: String, CodingKey {
            case id
            case commonName = "common_name"
            case scientificName = "scientific_name"
            case defaultImage = "default_image"
        }
    }
    
    private struct SpeciesDetailResponse: Codable {
        let id: Int
        let commonName: String
        let scientificName: [String]
        let watering: String?
        let wateringFrequency: WateringFrequency?
        let sunlight: [String]?
        let maintenance: String?
        let indoor: Bool?
        let defaultImage: PlantImageDTO?
        
        enum CodingKeys: String, CodingKey {
            case id
            case commonName = "common_name"
            case scientificName = "scientific_name"
            case watering
            case wateringFrequency = "watering_general_benchmark"
            case sunlight
            case maintenance
            case indoor
            case defaultImage = "default_image"
        }
    }
    
    // DTO for the nested image object returned by the API.
    private struct PlantImageDTO: Codable {
        let regularUrl: String?
        let originalUrl: String?
        let mediumUrl: String?
        let smallUrl: String?
        let thumbnail: String?
        
        enum CodingKeys: String, CodingKey {
            case regularUrl = "regular_url"
            case originalUrl = "original_url"
            case mediumUrl = "medium_url"
            case smallUrl = "small_url"
            case thumbnail
        }

        var bestImageUrl: String? {
            [regularUrl, originalUrl, mediumUrl, smallUrl, thumbnail]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty })
        }
    }
    
    // Legacy search entry point keeps compatibility with existing call sites.
    func searchPlants(matching query: String) async throws -> [PlantSpecies] {
        try await searchPlants(matching: query, page: 1, perPage: 30)
    }
    
    // Search for matching plant species.
    func searchPlants(matching query: String, page: Int, perPage: Int) async throws -> [PlantSpecies]
    {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw ApiError.encodingError
        }
        guard let encodedQuery = trimmedQuery.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        )
        else {
            throw ApiError.encodingError
        }
        
        let endpointCandidates = [Self.baseUrl, Self.fallbackBaseUrl].map {
            "\($0)/species-list?key=\(apiKey)&q=\(encodedQuery)"
        }

        var lastApiError: ApiError = .serverError
        for endpoint in endpointCandidates {
            guard let url = URL(string: endpoint) else {
                lastApiError = .invalidUrl
                continue
            }

            do {
                let (jsonData, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    lastApiError = .serverError
                    continue
                }

                let responseDecoded = try JSONDecoder().decode(
                    SpeciesListResponse.self,
                    from: jsonData
                )

                let payload: [PlantSpecies] = responseDecoded.data.map { apiItem in
                    PlantSpecies(
                        speciesId: apiItem.id,
                        commonName: apiItem.commonName,
                        scientificName: apiItem.scientificName.joined(separator: ", "),
                        watering: nil,
                        wateringFrequency: nil,
                        sunlight: nil,
                        maintenance: nil,
                        indoor: nil,
                        imageUrl: apiItem.defaultImage?.bestImageUrl,
                        careLevel: nil,
                        description: nil,
                    )
                }
                return payload
            } catch let error as DecodingError {
                print("Decoding error for endpoint \(endpoint): \(error)")
                lastApiError = .decodingError
            } catch {
                lastApiError = .serverError
            }
        }

        throw lastApiError
    }
    
    // Fetch detailed information for a specific plant by its ID.
    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        let endpointCandidates = [Self.baseUrl, Self.fallbackBaseUrl].map {
            "\($0)/species/detail/\(id)?key=\(apiKey)"
        }

        var lastApiError: ApiError = .serverError
        for endpoint in endpointCandidates {
            guard let url = URL(string: endpoint) else {
                lastApiError = .invalidUrl
                continue
            }

            do {
                let (jsonData, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    lastApiError = .serverError
                    continue
                }

                let apiResponse = try JSONDecoder().decode(
                    SpeciesDetailResponse.self,
                    from: jsonData
                )

                return PlantSpecies(
                    speciesId: apiResponse.id,
                    commonName: apiResponse.commonName,
                    scientificName: apiResponse.scientificName.joined(separator: ", "),
                    watering: apiResponse.watering,
                    wateringFrequency: apiResponse.wateringFrequency,
                    sunlight: apiResponse.sunlight,
                    maintenance: apiResponse.maintenance,
                    indoor: apiResponse.indoor,
                    imageUrl: apiResponse.defaultImage?.bestImageUrl,
                    careLevel: nil,
                    description: nil,
                )
            } catch let error as DecodingError {
                print("Decoding error for endpoint \(endpoint): \(error)")
                lastApiError = .decodingError
            } catch {
                lastApiError = .serverError
            }
        }

        throw lastApiError
    }
}
