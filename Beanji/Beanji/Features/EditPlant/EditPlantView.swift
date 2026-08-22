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
                Section("Basic information") {
                    TextField("Name", text: $viewModel.name)
                    TextField("Location", text: $viewModel.location)
                }

                Section("Care schedule") {
                    Stepper(
                        LocalizedText.waterEveryDays(
                            viewModel.wateringIntervalDays
                        ),
                        value: $viewModel.wateringIntervalDays,
                        in: 1 ... 30
                    )
                    Stepper(
                        LocalizedText.fertilizeEveryDays(
                            viewModel.fertilizingIntervalDays
                        ),
                        value: $viewModel.fertilizingIntervalDays,
                        in: 7 ... 90
                    )
                }

                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("Edit Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if viewModel.save() {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel("Save")
                    .disabled(!viewModel.canSave)
                }
            }
            .alert(
                "Error",
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
        location: "Living room"
    )

    EditPlantView(
        viewModel: EditPlantViewModel(plant: plant, repository: InMemoryUserPlantRepository())
    )
}
