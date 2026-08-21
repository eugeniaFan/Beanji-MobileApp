//
//  FilterChip.swift
//  Beanji
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
                .background(isSelected ? Color.brown : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : .primary.opacity(0.6))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        FilterChip(title: "Alle", isSelected: true, action: {})
        FilterChip(title: "Heute", isSelected: false, action: {})
    }
}
