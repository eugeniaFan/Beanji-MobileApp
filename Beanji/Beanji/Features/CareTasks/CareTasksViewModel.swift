//
//  CareTasksViewModel.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 07.08.26.
//

import Foundation
import Observation

@Observable
@MainActor
final class CareTasksViewModel {
    private let repository: UserPlantRepository
    private let careEventRepository: CareEventRepository
    private let calendar: Calendar
    private let now: () -> Date

    var plants: [Plant] = []
    var completedTasks: [CareTask] = []
    var selectedDate: Date
    var isLoading = false
    var errorMessage: String?

    init(
        repository: UserPlantRepository,
        careEventRepository: CareEventRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.careEventRepository = careEventRepository
        self.calendar = calendar
        self.now = now
        self.selectedDate = calendar.startOfDay(for: now())
    }

    var isSelectedDateToday:Bool {
        calendar.isDate(
            selectedDate,
            inSameDayAs: now()
        )
    }

    var selectedDayTasks: [CareTask] {
        // Calculate and return the result.

        if isSelectedDateToday {
            return todayTasks
        }
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let today = calendar.startOfDay(for: now())

        if selectedDay < today {
            return []
        }

        return openTasks
            .filter { task in
                calendar.isDate(
                    task.dueDate,
                    inSameDayAs: selectedDate
                )
            }
            .sorted { firstTask, secondTask in
                firstTask.dueDate < secondTask.dueDate
            }
    }

    // Replaces a plant's new open task with today's completion to avoid duplicate rows.
    var todayTasks: [CareTask] {
        let referenceDate = now()
        let completedTodayTasks = completedTasks.filter { task in
            guard let completedAt = task.completedAt else {
                return false
            }

            return calendar.isDate(
                completedAt,
                inSameDayAs: referenceDate
            )
        }

        let completedPlantIDs = Set(
            completedTodayTasks.map(\.plant.id)
        )
        let openTodayTasks = openTasks.filter {
            $0.daysUntilDue(
                referenceDate: referenceDate,
                using: calendar
            ) <= 0
            && !completedPlantIDs.contains($0.plant.id)
        }

        return (openTodayTasks + completedTodayTasks)
            .sorted { $0.dueDate < $1.dueDate }
    }

    var openTasks: [CareTask] {
        plants.map { plant in
            CareTask.watering(
                for: plant,
                using: calendar
            )
        }
    }

    var weekDays: [CareCalendarDay] {
        let referenceDate = now()
        let calendar = mondayFirstCalendar

        let weekStart =
            calendar.dateInterval(
                of: .weekOfYear,
                for: referenceDate
            )?.start
            ?? calendar.startOfDay(for: referenceDate)

        // Markers show current schedules while completed events remain in history.
        let scheduledTasks = openTasks

        return (0..<7).map { dayOffset in
            let date =
                calendar.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: weekStart
                )
                ?? weekStart

            let hasWateringTask = scheduledTasks.contains { task in
                task.kind == .watering
                    && calendar.isDate(
                        task.dueDate,
                        inSameDayAs: date
                    )
            }

            return CareCalendarDay(
                date: date,
                isToday: calendar.isDate(
                    date,
                    inSameDayAs: referenceDate
                ),
                hasWateringTask: hasWateringTask
            )
        }
    }

    var emptyStateText: String {
        if isSelectedDateToday {
            return String(
                localized: "No watering tasks are due today."
            )
        }

        if calendar.startOfDay(for: selectedDate)
            < calendar.startOfDay(for: now()) {
            return String(
                localized: "Overdue tasks are shown under Today."
            )
        }

        return String(
            localized: "No watering tasks are scheduled for this day."
        )
    }

    // Loads plants independently so event-history failures do not hide open tasks.
    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            plants = try repository.fetchAllPlants()
        } catch {
            errorMessage = String(localized: "Plants could not be loaded.")
            return
        }

        do {
            let storedEvents = try careEventRepository.fetchAllEvents()
            completedTasks = makeCompletedTasks(
                from: storedEvents,
                matching: plants
            )
            errorMessage = nil
        } catch {
            completedTasks = []
            errorMessage = String(
                localized: "Completed care tasks could not be loaded."
            )
        }
    }

    // Prevents duplicate watering events when completion is triggered more than once.
    private func wasWateredToday(_ task: CareTask) -> Bool {
        let referenceDate = now()

        return completedTasks.contains { completedTask in
            guard
                completedTask.plant.id == task.plant.id,
                completedTask.kind == .watering,
                let completedAt = completedTask.completedAt
            else {
                return false
            }

            return calendar.isDate(
                completedAt,
                inSameDayAs: referenceDate
            )
        }
    }

    func complete(_ task: CareTask) async {
        guard !wasWateredToday(task) else {
            return
        }

        switch task.kind {
        case .watering:
            await completeWatering(task)
        }
    }

    func dueText(for task: CareTask) -> String {
        let daysUntilDue = task.daysUntilDue(
            referenceDate: now(),
            using: calendar
        )

        return CareDueTextFormatter.text(
            daysUntilDue: daysUntilDue,
            dueDate: task.dueDate
        )
    }


    func isOverdue(_ task: CareTask) -> Bool {
        task.isOverdue(
            referenceDate: now(),
            using: calendar
        )
    }

    // Refreshes derived task state only after the repository records the atomic update.
    private func completeWatering(_ task: CareTask) async {
        do {
            try careEventRepository.recordWateringCompletion(
                for: task.plant,
                dueDate: task.dueDate,
                completedAt: now()
            )
            await loadTasks()
        } catch {
            errorMessage = String(
                localized: "The care task could not be saved."
            )
        }
    }

    // Keeps the week layout stable across device locale settings.
    private var mondayFirstCalendar: Calendar {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2
        return mondayCalendar
    }

    // Reconnects event snapshots to live plants and ignores events for deleted plants.
    private func makeCompletedTasks(
        from events: [CareEvent],
        matching plants: [Plant]
    ) -> [CareTask] {
        let plantsByID = Dictionary(
            uniqueKeysWithValues: plants.map {
                ($0.id, $0)
            }
        )

        return events.compactMap { event in
            guard
                event.kind == .watering,
                let plant = plantsByID[event.plantID]
            else {
                return nil
            }

            return CareTask(
                plant: plant,
                kind: event.kind,
                dueDate: event.dueDate,
                completedAt: event.completedAt
            )
        }
    }

}
