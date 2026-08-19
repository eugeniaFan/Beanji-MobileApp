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
    var selectedFilter: CareTaskFilter = .today
    var completedTasks: [CareTask] = []
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
    }

    var visibleTasks: [CareTask] {
        let referenceDate = now()

        switch selectedFilter {
        case .today:
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

        case .tomorrow:
            return openTasks
                .filter {
                    $0.daysUntilDue(
                        referenceDate: referenceDate,
                        using: calendar
                    ) == 1
                }
                .sorted { $0.dueDate < $1.dueDate }

        case .nextThreeDays:
            return openTasks
                .filter {
                    let days = $0.daysUntilDue(
                        referenceDate: referenceDate,
                        using: calendar
                    )
                    return (2...3).contains(days)
                }
                .sorted { $0.dueDate < $1.dueDate }

        case .completed:
            return completedTasks
                .sorted {
                    ($0.completedAt ?? .distantPast)
                    > ($1.completedAt ?? .distantPast)
                }
        }
    }

    var openTasks: [CareTask] {
        plants.map { plant in
            CareTask.watering(
                for: plant,
                using: calendar
            )
        }
    }

    var emptyStateText: String {
        switch selectedFilter {
        case .today:
            return "Für heute ist alles erledigt."
        case .tomorrow:
            return "Für morgen sind keine Aufgaben geplant."
        case .nextThreeDays:
            return "In den nächsten drei Tagen steht nichts an."
        case .completed:
            return "Noch keine Aufgabe erledigt."
        }
    }

    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedPlants = try repository.fetchAllPlants()
            let storedEvents = try careEventRepository.fetchAllEvents()

            plants = loadedPlants
            completedTasks = makeCompletedTasks(
                from: storedEvents,
                matching: loadedPlants
            )
            errorMessage = nil
        } catch {
            errorMessage = "Pflanzen konnten nicht geladen werden."
        }
    }
    
    func wasWateredToday(_ task: CareTask) -> Bool {
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

    private func completeWatering(_ task: CareTask) async {
        do {
            try careEventRepository.recordWateringCompletion(
                for: task.plant,
                dueDate: task.dueDate,
                completedAt: now()
            )
            await loadTasks()
            errorMessage = nil
        } catch {
            errorMessage = "Die Aufgabe konnte nicht gespeichert werden."
        }
    }

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
