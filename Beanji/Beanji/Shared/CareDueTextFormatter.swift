//
//  CareDueTextFormatter.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 20.08.26.
//

import Foundation

// Prevents Care Tasks and Plant Detail from showing different due-status wording.
enum CareDueTextFormatter {
    static func text(daysUntilDue days: Int, dueDate: Date) -> String {
        switch days {
        case ..<0:
            let overdueDays = abs(days)
            return overdueDays == 1
                ? String(localized: "Overdue since yesterday")
                : LocalizedText.format(
                    "%lld days overdue",
                    Int64(overdueDays)
                )

        case 0:
            return String(localized: "Due today")

        case 1:
            return String(localized: "Due tomorrow")

        default:
            return dueDate.formatted(
                .dateTime
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
            )
        }
    }
}
