//
//  InMemoryCareEventRepository.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 19.08.26.
//
//  In-memory care-event repository for previews and tests.

import Foundation

@MainActor
final class InMemoryCareEventRepository: CareEventRepository {
    var mockEvents: [CareEvent] = []

    func fetchAllEvents() throws -> [CareEvent] {
        mockEvents.sorted {
            $0.completedAt > $1.completedAt
        }
    }

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
        mockEvents.append(event)

        return event
    }
}
