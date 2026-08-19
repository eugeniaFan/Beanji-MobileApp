//
//  CareTask.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 07.08.26.
//

import Foundation

struct CareTask: Identifiable {

    let plant: Plant
    let kind: CareKind
    let dueDate: Date
    let completedAt: Date?

    var id: String {
        "\(plant.id)-\(kind.rawValue)-\(dueDate.timeIntervalSince1970)"
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    static func watering(
        for plant: Plant,
        using calendar: Calendar
    ) -> CareTask {
        CareTask(
            plant: plant,
            kind: .watering,
            dueDate: plant.nextWateringDate(using: calendar),
            completedAt: nil
        )
    }

    func daysUntilDue(
        referenceDate: Date,
        using calendar: Calendar
    ) -> Int {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let dueDay = calendar.startOfDay(for: dueDate)

        return calendar.dateComponents(
            [.day],
            from: referenceDay,
            to: dueDay
        ).day ?? 0
    }

    func isOverdue(
        referenceDate: Date,
        using calendar: Calendar
    ) -> Bool {
        daysUntilDue(
            referenceDate: referenceDate,
            using: calendar
        ) < 0
    }
}
