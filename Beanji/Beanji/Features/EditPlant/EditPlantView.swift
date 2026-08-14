//
//  EditPlantView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 11.08.26.
//

import SwiftUI

struct EditPlantView: View {
    @State private var viewModel: EditPlantViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: EditPlantViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("Basis") {
                    TextField("Name", text: $viewModel.name)
                    TextField("Standort", text: $viewModel.location)
                }

                Section("Pflege") {
                    Stepper(
                        "Gießen alle \(viewModel.wateringIntervalDays) Tage",
                        value: $viewModel.wateringIntervalDays,
                        in: 1 ... 30
                    )
                    Stepper(
                        "Düngen alle \(viewModel.fertilizingIntervalDays) Tage",
                        value: $viewModel.fertilizingIntervalDays,
                        in: 7 ... 90
                    )
                }

                Section("Notizen") {
                    TextField("Notizen", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("Pflanze bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .accessibilityLabel("Speichern")
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
            .alert(
                "Fehler",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
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
        createdAt: Date(),
        location: "Wohnzimmer"
    )

    EditPlantView(
        viewModel: EditPlantViewModel(plant: plant, repository: MockPlantRepository())
    )
}
