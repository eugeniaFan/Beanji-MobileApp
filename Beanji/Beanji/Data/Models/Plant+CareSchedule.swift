//
//  Plant+CareSchedule.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 21.08.26.
//
//  Keeps personal care-date calculations close to the Plant domain model.

import Foundation

extension Plant {
    func nextWateringDate(using calendar: Calendar = .current) -> Date {
        nextCareDate(
            after: lastWatered,
            intervalDays: wateringIntervalDays,
            using: calendar
        )
    }

    // Negative values indicate how many days the plant is overdue.
    func daysUntilNextWatering(
        using calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> Int {
        daysUntil(
            nextWateringDate(using: calendar),
            using: calendar,
            referenceDate: referenceDate
        )
    }

    func nextFertilizingDate(using calendar: Calendar = .current) -> Date {
        nextCareDate(
            after: lastFertilized,
            intervalDays: fertilizingIntervalDays,
            using: calendar
        )
    }

    // Negative values indicate how many days fertilizing is overdue.
    func daysUntilNextFertilizing(
        using calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> Int {
        daysUntil(
            nextFertilizingDate(using: calendar),
            using: calendar,
            referenceDate: referenceDate
        )
    }

    private func nextCareDate(
        after lastCareDate: Date,
        intervalDays: Int,
        using calendar: Calendar
    ) -> Date {
        calendar.date(
            byAdding: .day,
            value: intervalDays,
            to: lastCareDate
        ) ?? lastCareDate
    }

    private func daysUntil(
        _ dueDate: Date,
        using calendar: Calendar,
        referenceDate: Date
    ) -> Int {
        let dueDay = calendar.startOfDay(for: dueDate)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        return calendar.dateComponents(
            [.day],
            from: referenceDay,
            to: dueDay
        ).day ?? 0
    }
}

