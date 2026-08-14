//
//  FilterChip.swift
//  StudentProjekt
//
//  Created by Eugenia Fanenstiel on 25.06.26.
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    HStack {
        FilterChip(title: "Alle", isSelected: true, action: {})
        FilterChip(title: "Heute", isSelected: false, action: {})
    }
}
