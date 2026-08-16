//
//  AllPlantsView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 11.06.26.
//

import SwiftData
import SwiftUI

struct AllPlantsView: View {

    @State private var viewModel: AllPlantsViewModel

    init(viewModel: AllPlantsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                headerTitle
                pageSelector
                searchField
                searchFeedback
                filterChips
                Divider()

                // MARK: - Plant Pages

                TabView(selection: $viewModel.selectedPage) {
                    myPlantsGrid
                        .tag(PlantListPage.myPlants)

                    allPlantsGrid
                        .tag(PlantListPage.allPlants)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding([.leading, .trailing], 20)
            .background(Color(.systemGray6))
            .sheet(
                isPresented: $viewModel.showingAddPlant,
                onDismiss: {
                    Task {
                        await viewModel.loadMyPlants()
                    }
                }
            ) {

            }
            .overlay(alignment: .bottomTrailing) {
                if viewModel.selectedPage == .myPlants {
                   
                }
            }
        }
        .alert(
            "Pflanze löschen?",
            isPresented: Binding(
                get: { viewModel.plantToDelete != nil },
                set: { if !$0 { viewModel.plantToDelete = nil } }
            )
        ) {
            Button("Löschen", role: .destructive) {
                if let plant = viewModel.plantToDelete {
                    Task {
                        await viewModel.deletePlant(plant)
                        viewModel.plantToDelete = nil
                    }
                }
            }

            Button("Abbrechen", role: .cancel) {
                viewModel.plantToDelete = nil
            }

        } message: {
            if let plant = viewModel.plantToDelete {
                Text("\"\(plant.name)\" wird dauerhaft gelöscht.")
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
        .task {
            await viewModel.loadInitialData()
        }
    }

    private var headerTitle: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(viewModel.selectedPage.title))
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
        }
    }

    private var searchField: some View {

        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Pflanzen suchen...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    if viewModel.selectedPage == .allPlants {
                        Task { await viewModel.performApiSearch() }
                    }
                }
            if viewModel.selectedPage == .allPlants
                && !viewModel.searchText.isEmpty
            {
                Button {
                    Task { await viewModel.performApiSearch() }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(viewModel.filters, id: \.self) { filter in
                    FilterChip(
                        title: String(
                            localized: LocalizedStringResource(
                                stringLiteral: filter
                            )
                        ),
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                    }
                }
            }
        }
    }

    private var pageSelector: some View {
        HStack(spacing: 0) {
            ForEach(PlantListPage.allCases) { page in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedPage = page
                    }
                } label: {
                    Text(LocalizedStringKey(page.title))
                        .font(
                            .subheadline.weight(
                                viewModel.selectedPage == page
                                    ? .semibold : .regular
                            )
                        )
                        .foregroundStyle(
                            viewModel.selectedPage == page
                                ? .primary : .secondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedPage == page
                                ? Color(.systemBackground)
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }

    private var myPlantsGrid: some View {
        plantGrid(
            isLoading: viewModel.isLoading,
            isEmpty: viewModel.filteredMyPlants.isEmpty,
            emptyMessage: "Noch keine eigenen Pflanzen."
        ) {
            ForEach(viewModel.filteredMyPlants) { plant in
                NavigationLink {
                    PlantDetailView(
                        viewModel: viewModel.makeDetailViewModel(for: plant) {
                            Task { await viewModel.loadMyPlants() }
                        }
                    )
                } label: {
                    PlantCardView(
                        plant: plant,
                        onDelete: {
                            viewModel.plantToDelete = plant
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var allPlantsGrid: some View {
        plantGrid(
            isLoading: viewModel.isCatalogLoading,
            isEmpty: viewModel.filteredCatalogPlants.isEmpty,
            emptyMessage: "Keine Pflanzen im Katalog gefunden."
        ) {
            ForEach(viewModel.filteredCatalogPlants) { species in
                NavigationLink {
                    let detailViewModel =
                        viewModel.makeReadOnlySpeciesDetailViewModel(
                            for: species
                        )

                    PlantDetailView(viewModel: detailViewModel)
                        .onDisappear {
                            guard detailViewModel.didFinishAddToMyPlants else {
                                return
                            }

                            Task {
                                await viewModel.loadMyPlants()
                            }
                        }.task { await detailViewModel.loadFullDetail() }
                } label: {
                    SpeciesCardView(species: species)
                }
                .buttonStyle(.plain)
                .task {
                    await viewModel.loadNextCatalogPageIfNeeded(
                        current: species
                    )
                }
            }
        }
    }
    @ViewBuilder
    private var searchFeedback: some View {
        if let count = viewModel.searchResultCount {
            Text("Treffer: \(count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func plantGrid<Content: View>(
        isLoading: Bool,
        isEmpty: Bool,
        emptyMessage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            if isLoading && isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    content()
                }

                if isLoading {
                    ProgressView()
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    AllPlantsView(
        viewModel: AllPlantsViewModel(
            catalogService: PreviewPlantProvider(),
            repository: InMemoryUserPlantRepository()
        )
    )
    .modelContainer(for: [Plant.self, PlantSpeciesInfo.self], inMemory: true)
}
