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
                HStack(alignment: .top) {
                    HStack (spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.white)
                        Text(nextWateringText(for: plant))
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                    }.padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(waterStatusColor(for: plant))
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
                    Label("Löschen", systemImage: "trash")
                }
            }
            
        }
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
