//
//  CareTasksRow.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 07.08.26.
//

import SwiftUI

struct CareTasksRow: View {
    let task: CareTask
    let dueText: String
    let isOverdue: Bool

    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            PlantImageView(
                plant: task.plant,
                height: 64,
                width: 64,
                cornerRadius: 12
            )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(task.plant.name)
                    .font(.headline)

                if !task.plant.speciesName.isEmpty {
                    Text(task.plant.speciesName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Label {
                    Text(statusText)
                } icon: {
                    Image(systemName: statusIcon)
                }
                .font(.caption)
                .foregroundStyle(statusStyle)
            }

            Spacer()

            if task.isCompleted {
                completedIndicator
            } else {
                completeButton
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var completeButton: some View {
        Button(action: onComplete) {
            VStack(spacing: 4) {
                Image(systemName: "circle")
                    .font(.title2)

                Text("Done")
                    .font(.caption2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mark \(task.plant.name) as watered")
    }

    private var completedIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)

            Text("Done")
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.green.opacity(0.9))
        .accessibilityElement(children: .combine)
    }
    
    private var statusText: String {
        if let completedAt = task.completedAt {
            let formattedTime = completedAt.formatted(
                date: .omitted,
                time: .shortened
            )
            return "Done at \(formattedTime)"
        }

        return dueText
    }

    private var statusIcon: String {
        task.isCompleted ? "checkmark" : "drop.fill"
    }

    private var statusStyle: some ShapeStyle {
        if task.isCompleted {
            return AnyShapeStyle(.secondary)
        }

        if isOverdue {
            return AnyShapeStyle(.red)
        }

        return AnyShapeStyle(.secondary)
    }
}

#Preview("Due Today") {
    let calendar = Calendar.current
    let today = Date()
    let lastWatered = calendar.date(
        byAdding: .day,
        value: -20,
        to: today
    )!
    
    let plantOne = Plant(
        name: "Monstera",
        speciesName: "Monstera deliciosa",
        lastWatered: lastWatered,
        lastFertilized: today,
        wateringIntervalDays: 20,
        fertilizingIntervalDays: 30,
        createdAt: today
    )

    let taskOne = CareTask(
        plant: plantOne,
        kind: .watering,
        dueDate: plantOne.nextWateringDate(using: calendar),
        completedAt: nil
    )
    
    CareTasksRow(
        task: taskOne,
        dueText: "Due today",
        isOverdue: false,
        onComplete: { }
    )
}

#Preview("Completed Today") {
    let today = Date()

    let plant = Plant(
        name: "Monstera",
        speciesName: "Monstera deliciosa",
        lastWatered: today,
        lastFertilized: today,
        wateringIntervalDays: 1,
        fertilizingIntervalDays: 30,
        createdAt: today
    )

    let task = CareTask(
        plant: plant,
        kind: .watering,
        dueDate: today,
        completedAt: today
    )

    CareTasksRow(
        task: task,
        dueText: "Due today",
        isOverdue: false,
        onComplete: {}
    )
}
