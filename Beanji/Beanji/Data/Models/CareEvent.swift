//
//  CareEvent.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 19.08.26.
//
//  Stores a completed care action for plants

import Foundation
import SwiftData

@Model
final class CareEvent: Identifiable {
    @Attribute(.unique) var id: UUID

    var plantID: UUID
    var plantName: String
    var kindRawValue: String
    var dueDate: Date
    var completedAt: Date

    var kind: CareKind {
        CareKind(rawValue: kindRawValue) ?? .watering
    }

    init(
        id: UUID = UUID(),
        plantID: UUID,
        plantName: String,
        kind: CareKind,
        dueDate: Date,
        completedAt: Date
    ) {
        self.id = id
        self.plantID = plantID
        self.plantName = plantName
        self.kindRawValue = kind.rawValue
        self.dueDate = dueDate
        self.completedAt = completedAt
    }
}
