//
//  SpeciesImageView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 28.06.26.
//

import SwiftUI

struct SpeciesImageView: View {
    let species: PlantSpecies
    var height: CGFloat = 140
    var width: CGFloat = 160
    var cornerRadius: CGFloat = 18
    var placeholderIcon: String = "leaf.fill"
    var errorIcon: String = "exclamationmark.triangle"

    var body: some View {
        ZStack {
            if let urlString = species.imageUrl,
                let url = URL(string: urlString)
            {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        Color.red.opacity(0.2)
                            .overlay {
                                Image(systemName: errorIcon)
                                    .font(.system(size: 48))
                                    .foregroundStyle(.red.opacity(0.6))
                            }

                    case .empty:
                        Color.green.opacity(0.1)
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                    @unknown default:
                        Color.red.opacity(0.2)
                            .overlay {
                                Image(systemName: errorIcon)
                                    .font(.system(size: 48))
                                    .foregroundStyle(.red.opacity(0.6))
                            }
                    }
                }
            } else {
                Color.green.opacity(0.1)
                Image(systemName: placeholderIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(.green.opacity(0.4))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private func placeholderView(color: Color, icon: String) -> some View {
        color.opacity(0.1)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(color.opacity(0.4))
            }
    }
}

#Preview {
    let species = PlantSpecies(
        speciesId: 1,
        commonName: "Monstera",
        scientificName: "Monstera deliciosa",
        watering: nil,
        wateringFrequency: nil,
        sunlight: nil,
        maintenance: nil,
        indoor: nil,
        imageUrl: nil,
        careLevel: nil,
        description: nil,
    )
    
    SpeciesImageView(species: species)
        .padding()
}
