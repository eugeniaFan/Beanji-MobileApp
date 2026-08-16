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

    var plants: [Plant] = []
    var selectedFilter: CareTaskFilter = .today
    var completedTasks: [CareTask] = []
    var isLoading = false
    var errorMessage: String?

    init(
        repository: UserPlantRepository,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    var visibleTasks: [CareTask] {
        switch selectedFilter {
        case .today:
            return openTasks
                .filter { task in
                    calendar.startOfDay(for: task.dueDate)
                    <= calendar.startOfDay(for: Date())
                }
                .sorted { $0.dueDate < $1.dueDate }

        case .tomorrow:
            guard let tomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: Date())
            ) else {
                return []
            }

            return openTasks
                .filter {
                    calendar.isDate($0.dueDate, inSameDayAs: tomorrow)
                }
                .sorted { $0.dueDate < $1.dueDate }

        case .nextThreeDays:
            let today = calendar.startOfDay(for: Date())

            guard
                let dayAfterTomorrow = calendar.date(
                    byAdding: .day,
                    value: 2,
                    to: today
                ),
                let endDate = calendar.date(
                    byAdding: .day,
                    value: 3,
                    to: today
                )
            else {
                return []
            }

            return openTasks
                .filter {
                    let dueDate = calendar.startOfDay(for: $0.dueDate)
                    return dueDate >= dayAfterTomorrow && dueDate <= endDate
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
            CareTask(
                plant: plant,
                kind: .watering,
                dueDate: nextWateringDate(for: plant),
                completedAt: nil
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
            plants = try await repository.fetchAllPlants()
            errorMessage = nil
        } catch {
            errorMessage = "Pflanzen konnten nicht geladen werden."
        }
    }

    func complete(_ task: CareTask) async {
        switch task.kind {
        case .watering:
            await completeWatering(task)
        }
    }

    func dueText(for task: CareTask) -> String {
        let dueDay = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: task.dueDate)
        ).day ?? 0
        return CareDueTextFormatter.text(daysUntilDue: dueDay, dueDate: task.dueDate)
    }


    func isOverdue(_ task: CareTask) -> Bool {
        calendar.startOfDay(for: task.dueDate)
        < calendar.startOfDay(for: Date())
    }

    private func completeWatering(_ task: CareTask) async {
        let completionDate = Date()
        let plant = task.plant

        plant.lastWatered = completionDate

        do {
            try await repository.updatePlant(plant)

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

    private func nextWateringDate(for plant: Plant) -> Date {
        calendar.date(
            byAdding: .day,
            value: plant.wateringIntervalDays,
            to: plant.lastWatered
        ) ?? plant.lastWatered
    }
}
