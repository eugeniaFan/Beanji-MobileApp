//
//  CareTaskFilter.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 07.08.26.
//

import Foundation

enum CareTaskFilter: String, CaseIterable, Identifiable {
    case today = "Heute"
    case tomorrow = "Morgen"
    case nextThreeDays = "3 Tage"
    case completed = "Erledigt"

    var id: Self { self }
}

// Shared, localized "due" text used by any care-related view that needs to describe
// how many days remain (or have passed) until a task is due.
enum CareDueTextFormatter {
    static func text(daysUntilDue days: Int, dueDate: Date) -> String {
        switch days {
        case ..<0:
            let overdueDays = abs(days)
            return overdueDays == 1
                ? "Seit gestern fällig"
                : "Seit \(overdueDays) Tagen fällig"

        case 0:
            return "Heute fällig"

        case 1:
            return "Morgen fällig"

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
