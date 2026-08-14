//
//  PlantImage.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 23.06.26.
//

import SwiftUI

struct PlantImageView: View {
    let plant: Plant
    var height: CGFloat = 140
    var width: CGFloat = 160
    var cornerRadius: CGFloat = 18
    var placeholderIcon: String = "leaf.fill"
    var errorIcon: String = "exclamationmark.triangle"

    var body: some View {
        ZStack {
            if let photoData = plant.photoData,
                let uiImage = UIImage(data: photoData)
            {  // Success state
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()

            } else if plant.photoData != nil {
                // Error State
                Color.red.opacity(0.2)
                    .overlay {
                        Image(systemName: errorIcon)
                            .font(.system(size: 48))
                            .foregroundStyle(.red.opacity(0.6))
                    }
            } else {
                // Placeholer
                Color.green.opacity(0.1)
                    .overlay{
                        Image(systemName: placeholderIcon)
                            .font(.system(size: 48))
                            .foregroundStyle(.green.opacity(0.4))
                    }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    let plant = Plant(
        name: "Monstera",
        speciesName: "Monstera deliciosa",
        lastWatered: Date(),
        lastFertilized: Date(),
        wateringIntervalDays: 7,
        fertilizingIntervalDays: 30,
        createdAt: Date()
    )
    PlantImageView(plant: plant)
        .frame(width: 180)
        .padding()
}
