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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    todaySection
                    CareWeekCalendarView(days: viewModel.weekDays)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .frame(
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
            }
            .scrollIndicators(.hidden)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .background(
                Color.pink
                    .opacity(0.09)
                    .ignoresSafeArea()
            )
            .task {
                await viewModel.loadTasks()
            }
            .refreshable {
                await viewModel.loadTasks()
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

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            if viewModel.isLoading && viewModel.todayTasks.isEmpty {
                loadingView
            }
            else if viewModel.todayTasks.isEmpty {
                emptyState
            }
            else {
                taskList
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Care")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 4)

            Text("What your plants need next.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var taskList: some View {
        LazyVStack(spacing: 12) {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.todayTasks) { task in
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
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Everything is good to go.")
                    .font(.headline)

                Text(viewModel.emptyStateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview("Care Tasks") {
    let repository = InMemoryUserPlantRepository()
    let careEventRepository = InMemoryCareEventRepository()
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
            repository: repository,
            careEventRepository: careEventRepository
        )
    )
}
