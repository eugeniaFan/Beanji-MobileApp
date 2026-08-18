//
//  AllPlantsView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 11.06.26.
//

import SwiftData
import SwiftUI

struct AllPlantsView: View {
    @Namespace private var pageSelectorAnimation
    @State private var viewModel: AllPlantsViewModel

    init(viewModel: AllPlantsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    private let floatingTabBarClearance: CGFloat = 24
    
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
                filterChips
                
                // MARK: - Plant Pages

                TabView(selection: $viewModel.selectedPage) {
                    myPlantsGrid
                        .tag(PlantListPage.myPlants)
                    
                    allPlantsGrid
                        .tag(PlantListPage.allPlants)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                )
                .ignoresSafeArea(.container, edges: .bottom)
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .background(
                Color.pink
                    .opacity(0.09)
            )
        }
        .alert(
            "Delete Plant?",
            isPresented: Binding(
                get: { viewModel.plantToDelete != nil },
                set: { if !$0 { viewModel.plantToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let plant = viewModel.plantToDelete {
                    Task {
                        await viewModel.deletePlant(plant)
                        viewModel.plantToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.plantToDelete = nil
            }
        } message: {
            if let plant = viewModel.plantToDelete {
                Text("\"\(plant.name)\" can not be restored.")
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
        .task {
            await viewModel.loadInitialData()
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Plants")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(
                "Search plants...",
                text: $viewModel.searchText
            )
            .textFieldStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    Color.primary.opacity(0.05),
                    lineWidth: 1
                )
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
        HStack(spacing: 4){
            ForEach(PlantListPage.allCases) { page in
                let isSelected = viewModel.selectedPage == page
                
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        viewModel.selectedPage = page
                    }
                } label: {
                    Text(LocalizedStringKey(page.title))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(
                            isSelected ? Color.white : Color.primary.opacity(0.6)
                        )
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 44
                        )
                        .background {
                            if (isSelected) {
                                Capsule()
                                    .fill(Color.brown)
                                    .matchedGeometryEffect(
                                        id: "selectedPage",
                                        in: pageSelectorAnimation
                                    )
                                    .shadow(
                                        color: .black.opacity(0.12),
                                        radius: 2,
                                        y: 2
                                    )
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityValue(
                    isSelected ? "Selected" : "Not selected"
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .background(
            Color(.systemBackground).opacity(0.9)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                Color.primary.opacity(0.05),
                lineWidth: 1
            )
        }
        .animation(
            .snappy(duration: 0.2),
            value: viewModel.selectedPage
        )
    }

    private var myPlantsGrid: some View {
        plantGrid(
            isLoading: viewModel.isLoading,
            isEmpty: viewModel.filteredMyPlants.isEmpty,
            emptyMessage: "No plants here."
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
            emptyMessage: "No Plants can be found in the local catalog."
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
            }
        }
    }

    @ViewBuilder
    private func plantGrid<Content: View>(
        isLoading: Bool,
        isEmpty: Bool,
        emptyMessage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Group {
            if isLoading && isEmpty {
                ProgressView()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            } else if isEmpty {
                VStack(spacing: 12) {
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        LazyVGrid(
                            columns: columns,
                            spacing: 16
                        ) {
                            content()
                        }
                        
                        if isLoading {
                            ProgressView()
                                .padding(.top, 16)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 16)
                }.contentMargins(
                    .bottom,
                    floatingTabBarClearance,
                    for: .scrollContent
                )
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
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
