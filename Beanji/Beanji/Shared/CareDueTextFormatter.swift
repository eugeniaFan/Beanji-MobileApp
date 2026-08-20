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
                ? "Overdue since yesterday"
                : "\(overdueDays) days overdue"

        case 0:
            return "Due today"

        case 1:
            return "Due tomorrow"

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
