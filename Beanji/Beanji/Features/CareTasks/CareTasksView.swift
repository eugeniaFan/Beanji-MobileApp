//
//  CareTasksView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 07.08.26.
//

import Foundation
import SwiftData
import SwiftUI

struct CareTasksView: View {

    @State private var viewModel: CareTasksViewModel

    init(viewModel: CareTasksViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                header
                filters

                if viewModel.isLoading && viewModel.visibleTasks.isEmpty {
                    loadingView
                }
                else if viewModel.visibleTasks.isEmpty {
                    emptyState
                }
                else {
                    taskList
                }
            }
            .padding(.horizontal)
            
            .background(Color(.pink .opacity(0.09)))
            .frame(maxWidth: .infinity, alignment: .leading)
            .navigationTitle("Beanji")
            .task {
                await viewModel.loadTasks()
            }
            .refreshable {
                await viewModel.loadTasks()
            }
            .alert(
                "Fehler",
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
        }.ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pflege")
                .font(.largeTitle.bold())

            Text("Was deine Pflanzen als Nächstes brauchen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CareTaskFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                viewModel.selectedFilter == filter
                                    ? Color.primary
                                    : Color(.secondarySystemGroupedBackground)
                            )
                            .foregroundStyle(
                                viewModel.selectedFilter == filter
                                    ? Color(.systemBackground)
                                    : Color.primary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.visibleTasks) { task in
                    CareTasksRow(
                        task: task,
                        dueText: viewModel.dueText(for: task),
                        isOverdue: viewModel.isOverdue(task)
                    ) {
                        Task {
                            await viewModel.complete(task)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Alles im grünen Bereich",
            systemImage: "leaf.circle",
            description: Text(viewModel.emptyStateText)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Care Tasks") {
    let repository = InMemoryUserPlantRepository()
    let calendar = Calendar.current

    repository.mockPlants = [
        // Overdue
        Plant(
            name: "Calathea",
            speciesName: "Calathea orbifolia",
            lastWatered: calendar.date(
                byAdding: .day,
                value: -5,
                to: Date()
            )!,
            lastFertilized: Date(),
            wateringIntervalDays: 3,
            fertilizingIntervalDays: 30,
            imageName: nil,
            createdAt: Date(),
            notes: nil,
            photoData: nil
        ),

        // Due today
        Plant(
            name: "Monstera",
            speciesName: "Monstera deliciosa",
            lastWatered: calendar.date(
                byAdding: .day,
                value: -3,
                to: Date()
            )!,
            lastFertilized: Date(),
            wateringIntervalDays: 3,
            fertilizingIntervalDays: 30,
            imageName: nil,
            createdAt: Date(),
            notes: nil,
            photoData: nil
        ),

        // Due tomorrow
        Plant(
            name: "Pilea",
            speciesName: "Pilea peperomioides",
            lastWatered: calendar.date(
                byAdding: .day,
                value: -2,
                to: Date()
            )!,
            lastFertilized: Date(),
            wateringIntervalDays: 3,
            fertilizingIntervalDays: 30,
            imageName: nil,
            createdAt: Date(),
            notes: nil,
            photoData: nil
        ),
    ]

    return CareTasksView(
        viewModel: CareTasksViewModel(
            repository: repository
        )
    )
}
