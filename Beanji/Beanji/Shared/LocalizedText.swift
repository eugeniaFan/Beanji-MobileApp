//
//  LocalizedText.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 21.08.26.
//

import Foundation

// Keeps dynamic String Catalog formatting consistent outside SwiftUI views.
enum LocalizedText {
    static func format(
        _ key: String.LocalizationValue,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: String(localized: key),
            locale: Locale.current,
            arguments: arguments
        )
    }

    // Resolves catalog-backed data while preserving unknown remote values.
    static func catalogValue(_ value: String) -> String {
        String(
            localized: LocalizedStringResource(
                stringLiteral: value
            )
        )
    }

    static func everyDays(_ days: Int) -> String {
        guard days != 1 else {
            return String(localized: "Every day")
        }

        return format("Every %lld days", Int64(days))
    }

    static func waterEveryDays(_ days: Int) -> String {
        guard days != 1 else {
            return String(localized: "Water every day")
        }

        return format("Water every %lld days", Int64(days))
    }

    static func fertilizeEveryDays(_ days: Int) -> String {
        guard days != 1 else {
            return String(localized: "Fertilize every day")
        }

        return format("Fertilize every %lld days", Int64(days))
    }

    static func dayCount(_ days: Int) -> String {
        guard days != 1 else {
            return String(localized: "1 day")
        }

        return format("%lld days", Int64(days))
    }
}
