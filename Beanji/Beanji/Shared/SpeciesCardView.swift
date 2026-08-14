//
//  SpeciesCardView.swift
//  StudentProjekt
//
//  Created by Eugenia Fanenstiel on 28.06.26.
//

import SwiftUI

struct SpeciesCardView: View {
    let species: PlantSpecies
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                SpeciesImageView(species: species)
                
                HStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.white)
                    Text("Katalog")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue)
                .clipShape(Capsule())
                .shadow(radius: 2)
                .padding(8)
            }
            
            VStack(alignment: .leading) {
                Text(species.commonName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(species.scientificName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
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
    SpeciesCardView(species: species)
        .frame(width: 180)
        .padding()
}
