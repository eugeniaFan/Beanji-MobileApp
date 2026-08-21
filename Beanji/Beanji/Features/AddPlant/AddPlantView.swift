//
//  AddPlantView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 21.08.26.
//

import SwiftUI

struct AddPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddPlantViewModel

    init(viewModel: AddPlantViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    TextField("Plant name", text: $viewModel.name)
                    TextField("Species name", text: $viewModel.speciesName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Plant")
                } footer: {
                    Text("Plant name and species are required.")
                }

                Section("Care schedule") {
                    DatePicker(
                        "Last watered",
                        selection: $viewModel.lastWatered,
                        displayedComponents: .date
                    )

                    Stepper(
                        "Water every \(viewModel.wateringIntervalDays) days",
                        value: $viewModel.wateringIntervalDays,
                        in: 1 ... 30
                    )

                    DatePicker(
                        "Last fertilized",
                        selection: $viewModel.lastFertilized,
                        displayedComponents: .date
                    )

                    Stepper(
                        "Fertilize every \(viewModel.fertilizingIntervalDays) days",
                        value: $viewModel.fertilizingIntervalDays,
                        in: 7 ... 90
                    )
                }

                Section("Optional details") {
                    TextField("Location", text: $viewModel.location)
                    TextField(
                        "Notes",
                        text: $viewModel.notes,
                        axis: .vertical
                    )
                    .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlant()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: {
                        if !$0 {
                            viewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // Dismisses only after persistence succeeds so entered values remain available on errors.
    private func savePlant() {
        guard viewModel.save() else {
            return
        }

        dismiss()
    }
}

#Preview {
    AddPlantView(
        viewModel: AddPlantViewModel(
            repository: InMemoryUserPlantRepository()
        )
    )
}
