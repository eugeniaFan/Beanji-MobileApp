//
//  CareEventRepository.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 19.08.26.
//
//  Defines persistence operations for completed care actions.

import Foundation

enum CareEventRepositoryError: LocalizedError {
    case fetchFailed(underlying: Error)
    case recordFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return String(
                localized: "Could not load completed care actions."
            )
        case .recordFailed:
            return String(
                localized: "Could not save the completed care action."
            )
        }
    }
}

@MainActor
protocol CareEventRepository {
    func fetchAllEvents() throws -> [CareEvent]

    @discardableResult
    func recordWateringCompletion(
        for plant: Plant,
        dueDate: Date,
        completedAt: Date
    ) throws -> CareEvent
}
