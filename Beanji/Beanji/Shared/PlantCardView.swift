//
//  PlantCardView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 23.06.26.
//

import SwiftUI

struct PlantCardView: View {
    let plant: Plant
    let onDelete: () -> Void
    var allowsDelete: Bool = true

    var cornerRadius: CGFloat = 14
    var placeholderSystemImage: String = "leaf.fill"
    var errorSystemImage: String = "exclamationmark.triangle"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .top) {
                PlantImageView(plant: plant)
                    .accessibilityHidden(true)
                HStack(alignment: .top) {
                    HStack (spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.white)
                        Text(nextWateringText)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                    }.padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(waterStatusColor)
                        .clipShape(Capsule())
                        .shadow(radius: 2)
                    
                    Spacer()
                    VStack {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.red.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .accessibilityLabel(
                            LocalizedText.format(
                                "Delete %@",
                                plant.name
                            )
                        )
                    }
                }
            }.frame(width: 160, height: 140)
              
            VStack(alignment: .leading) {
                Text(plant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if !plant.speciesName.isEmpty {
                    Text(plant.speciesName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .clipped()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contextMenu {
            if allowsDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
        }
    }

    private var nextWateringText: String {
        let days = plant.daysUntilNextWatering()

        if days <= 0 {
            return String(localized: "Water today")
        } else if days == 1 {
            return String(localized: "Tomorrow")
        } else {
            return LocalizedText.format("In %lld days", Int64(days))
        }
    }

    private var waterStatusColor: Color {
        plant.daysUntilNextWatering() <= 1 ? .orange : .blue
    }
}

#Preview {
    let plant = Plant(
        name: "Monstera",
        speciesName: "Monstera deliciosa",
        lastWatered: Date().addingTimeInterval(-86400 * 2),
        lastFertilized: Date(),
        wateringIntervalDays: 20,
        fertilizingIntervalDays: 30,
        createdAt: Date(),
    )

    PlantCardView(plant: plant, onDelete: {})
}
