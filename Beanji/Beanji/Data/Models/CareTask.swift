//
//  CareTask.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 07.08.26.
//

import Foundation

struct CareTask: Identifiable {
    enum Kind: Equatable{
        case watering
    }

    let plant: Plant
    let kind: Kind
    let dueDate: Date
    let completedAt: Date?

    var id: String {
        "\(plant.id)-watering-\(dueDate.timeIntervalSince1970)"
    }

    var isCompleted: Bool {
        completedAt != nil
    }
}
