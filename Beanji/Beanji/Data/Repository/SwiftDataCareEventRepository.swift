//
//  SwiftDataCareEventRepository.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 19.08.26.
//
//  Persists completed care actions with SwiftData.

import Foundation
import SwiftData

@MainActor
final class SwiftDataCareEventRepository: CareEventRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllEvents() throws -> [CareEvent] {
        let descriptor = FetchDescriptor<CareEvent>(
            sortBy: [
                SortDescriptor(\.completedAt, order: .reverse)
            ]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw CareEventRepositoryError.fetchFailed(
                underlying: error
            )
        }
    }

    // Update lastWatered and insert the event in one transaction.
    // A failed save rolls back both changes.
    @discardableResult
    func recordWateringCompletion(
        for plant: Plant,
        dueDate: Date,
        completedAt: Date
    ) throws -> CareEvent {
        let event = CareEvent(
            plantID: plant.id,
            plantName: plant.name,
            kind: .watering,
            dueDate: dueDate,
            completedAt: completedAt
        )

        plant.lastWatered = completedAt
        modelContext.insert(event)

        do {
            try modelContext.save()
            return event
        } catch {
            modelContext.rollback()

            throw CareEventRepositoryError.recordFailed(
                underlying: error
            )
        }
    }
}
