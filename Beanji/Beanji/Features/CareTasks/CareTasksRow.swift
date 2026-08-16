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
        HStack(spacing: 14) {
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
            }
            else {
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
                Image(systemName: "checkmark.circle")
                    .font(.title2)

                Text("Erledigt")
                    .font(.caption2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.plant.name) als gegossen markieren")
    }

    private var completedIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)

            Text("Erledigt")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }

    private var statusText: String {
        if let completedAt = task.completedAt {
            return "Erledigt um \(completedAt.formatted(date: .omitted, time: .shortened))"
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
