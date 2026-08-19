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
    private let calendar: Calendar
    private let now: () -> Date

    var plants: [Plant] = []
    var selectedFilter: CareTaskFilter = .today
    var completedTasks: [CareTask] = []
    var isLoading = false
    var errorMessage: String?

    init(
        repository: UserPlantRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    var visibleTasks: [CareTask] {
        let referenceDate = now()

        switch selectedFilter {
        case .today:
            let completedTodayTasks = completedTasks.filter {
                $0.daysUntilDue(
                    referenceDate: referenceDate,
                    using: calendar
                ) <= 0
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
            plants = try repository.fetchAllPlants()
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
        let completionDate = now()
        let plant = task.plant

        plant.lastWatered = completionDate

        do {
            try repository.updatePlant(plant)

            completedTasks.removeAll {
                $0.plant.id == plant.id
                && $0.kind == .watering
            }

            completedTasks.append(
                CareTask(
                    plant: plant,
                    kind: .watering,
                    dueDate: task.dueDate,
                    completedAt: completionDate
                )
            )

            await loadTasks()
            errorMessage = nil
        } catch {
            errorMessage = "Die Aufgabe konnte nicht gespeichert werden."
        }
    }

}
