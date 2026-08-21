//
//  PlantDetailView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 24.06.26.
//

import SwiftUI

struct PlantDetailView: View {
    @State var viewModel: PlantDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isDescriptionExpanded = false
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        ScrollView {
            VStack(spacing: 0) {
                headerImage

                VStack(alignment: .leading, spacing: 16) {
                    if let description = viewModel.descriptionText {
                        descriptionSection(description)
                    }
                    conditionsSection
                    notesCard
                        
                    if viewModel.hasCarePlan {
                        carePlanSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            HStack {
                backButton
                Spacer()
                menuButton
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $bindableViewModel.showingEditSheet, onDismiss: {
            self.viewModel.editViewModel = nil
        }) {
            if let editVM = self.viewModel.editViewModel {
                EditPlantView(viewModel: editVM)
            } else {
                Text("Editing is unavailable.")
            }
        }
        .alert("Delete plant?", isPresented: $bindableViewModel.showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deletePlant()

                    if didDelete {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(viewModel.titleText) will be permanently removed.")
        }
        .alert("Add to My Plants", isPresented: $bindableViewModel.showingAddToMyPlantsAlert) {
            TextField("Custom name (optional)", text: $bindableViewModel.pendingCustomName)
            Button("Add") {
                Task {
                    let customName = viewModel.pendingCustomName.trimmingCharacters(in: .whitespacesAndNewlines)
                    await viewModel.addCurrentSpeciesToMyPlants(userPlantName: customName.isEmpty ? nil : customName)
                    if viewModel.didFinishAddToMyPlants {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This species will be saved as a new plant in My Plants.")
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
        .task {
            await viewModel.loadFullDetail()
        }
    }

    // MARK: - Header

    private var headerImage: some View {
        ZStack(alignment: .bottomLeading) {
            plantImageOrPlaceholder
                .frame(height: 320)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.61)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 320)

            headerTextOverlay
        }
        .ignoresSafeArea(edges: .top)
    }

    private var headerTextOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(viewModel.titleText)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let locationText = viewModel.locationText {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                        Text(locationText)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                }
            }

            Text(viewModel.subtitleText)
                .font(.title2)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(20)
    }

    @ViewBuilder
    private var plantImageOrPlaceholder: some View {
        if let photoData = viewModel.editablePlant?.photoData,
            let uiImage = UIImage(data: photoData)
        {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        }
        else if let imageUrl = viewModel.species.imageUrl,
            let url = URL(string: imageUrl)
        {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderGradient
                @unknown default:
                    placeholderGradient
                }
            }
        }
        else {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.35), Color.green.opacity(0.62)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green.opacity(1))
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(16)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var menuButton: some View {
        Menu {
            if viewModel.canEdit {
                Button {
                    viewModel.showingEditSheet = true
                } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    viewModel.showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            else if viewModel.canAddToMyPlants {
                Button {
                    viewModel.showingAddToMyPlantsAlert = true
                } label: {
                    Label("Add to My Plants", systemImage: "plus")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .padding(16)
                .background(.ultraThinMaterial, in: Circle())
        }
    }
    
    // MARK: - Notes
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Notizen", systemImage: "note.text")
                    .font(.headline)
                Spacer()
            }

            if let notes = viewModel.notesText, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                Text("No notes yet.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Description

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Beschreibung")
                .font(.headline)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(isDescriptionExpanded ? nil : 4)

            if !isDescriptionExpanded {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded = true
                    }
                } label: {
                    Label("Show more", systemImage: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Ideal Conditions

    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ideal Conditions")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
            ) {
                ConditionTile(
                    icon: "drop.fill",
                    color: .blue,
                    title: "Water",
                    value: viewModel.wateringConditionText
                )
                ConditionTile(
                    icon: "leaf.arrow.circlepath",
                    color: .green,
                    title: "Fertilizer",
                    value: viewModel.fertilizingConditionText
                )
                if viewModel.hasSpeciesConditions {
                    ConditionTile(
                        icon: "sun.max.fill",
                        color: .orange,
                        title: "Sunlight",
                        value: viewModel.sunlightConditionText
                    )
                    ConditionTile(
                        icon: "sparkles",
                        color: .mint,
                        title: "Care",
                        value: viewModel.careConditionText
                    )
                }
            }
        }
    }
    // MARK: - Care Plan

    private var carePlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Care Plan")
                .font(.headline)

            VStack(spacing: 12) {
                PlanTile(
                    icon: "calendar",
                    color: .blue,
                    title: "Next Watering",
                    value: viewModel.nextWateringDueText ?? "Unknown"
                )
                PlanTile(
                    icon: "calendar",
                    color: .green,
                    title: "Next Fertilizing",
                    value: viewModel.nextFertilizingDueText ?? "Unknown"
                )
            }
        }
    }
}
 
// MARK: - Subviews

private struct ConditionTile: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 34, height: 34)
                    .background(
                        color.opacity(0.15),
                        in: RoundedRectangle(
                            cornerRadius: 9,
                            style: .continuous
                        )
                    )

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2, reservesSpace: true)
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            minHeight: 106,
            alignment: .topLeading
        )
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PlanTile: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    let plant = Plant(
        name: "Monstera",
        speciesName: "Monstera deliciosa",
        lastWatered: Date().addingTimeInterval(-86400 * 2),
        lastFertilized: Date(),
        wateringIntervalDays: 7,
        fertilizingIntervalDays: 30,
        createdAt: Date(),
        notes: "New leaves are developing well.",
        photoData: nil
    )

    NavigationStack {
        PlantDetailView(
            viewModel: PlantDetailViewModel(
                plant: plant,
                repository: InMemoryUserPlantRepository(),
                plantSpeciesProvider: LocalPlantCatalog()
            )
        )
    }
}
