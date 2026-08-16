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
                Text("Kein Bearbeitungsmodell verfügbar.")
            }
        }
        .alert("Pflanze löschen?", isPresented: $bindableViewModel.showingDeleteAlert) {
            Button("Löschen", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deletePlant()

                    if didDelete {
                        dismiss()
                    }
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("„\(viewModel.titleText)“ wird dauerhaft entfernt.")
        }
        .alert("Zu meinen Pflanzen hinzufügen", isPresented: $bindableViewModel.showingAddToMyPlantsAlert) {
            TextField("Eigener Name (optional)", text: $bindableViewModel.pendingCustomName)
            Button("Hinzufügen") {
                Task {
                    let customName = viewModel.pendingCustomName.trimmingCharacters(in: .whitespacesAndNewlines)
                    await viewModel.addCurrentSpeciesToMyPlants(userPlantName: customName.isEmpty ? nil : customName)
                    if viewModel.didFinishAddToMyPlants {
                        dismiss()
                    }
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Die Art wird als neue Pflanze in „Meine Pflanzen“ gespeichert.")
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
                    Label("Löschen", systemImage: "trash")
                }
            }
            else if viewModel.canAddToMyPlants {
                Button {
                    viewModel.showingAddToMyPlantsAlert = true
                } label: {
                    Label("Zu meinen Pflanzen hinzufügen", systemImage: "plus")
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
                Text("Keine Notizen vorhanden.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Beschreibung

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
                    Label("Mehr anzeigen", systemImage: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Idealbedingungen

    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Idealbedingungen")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 12
            ) {
                ConditionTile(
                    icon: "drop.fill",
                    color: .blue,
                    title: "Wasser",
                    value: viewModel.wateringConditionText
                )
                ConditionTile(
                    icon: "leaf.arrow.circlepath",
                    color: .green,
                    title: "Düngen",
                    value: viewModel.fertilizingConditionText
                )
                ConditionTile(
                    icon: "sun.max.fill",
                    color: .orange,
                    title: "Sonne",
                    value: viewModel.sunlightConditionText
                )
                ConditionTile(
                    icon: "sparkles",
                    color: .mint,
                    title: "Pflege",
                    value: viewModel.careConditionText
                )
            }
        }
    }
    // MARK: - Pflegeplan

    private var carePlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pflegeplan")
                .font(.headline)

            VStack(spacing: 12) {
                PlanTile(
                    icon: "drop.fill",
                    color: .blue,
                    title: "Gießen",
                    value: viewModel.nextWateringDueText ?? "Unbekannt"
                )
                PlanTile(
                    icon: "calendar",
                    color: .teal,
                    title: "Gießintervall",
                    value: viewModel.wateringIntervalPlanText ?? "Unbekannt"
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
        HStack(alignment: .top, spacing: 12, ) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        notes: "Neue Blätter entwickeln sich gut.",
        photoData: nil
    )

    NavigationStack {
        PlantDetailView(
            viewModel: PlantDetailViewModel(
                plant: plant,
                repository: MockPlantRepository(),
                plantSpeciesProvider: LocalPlantCatalog()
            )
        )
    }
}
