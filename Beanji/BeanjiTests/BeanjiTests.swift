//
//  BeanjiTests.swift
//  BeanjiTests
//
//  Created by Eugenia Fanenstiel on 14.08.26.

import Foundation
import SwiftData
import Testing
@testable import Beanji


struct BeanjiTests {

    @Test
    @MainActor
    func clearingCatalogSearchShowsAllLocalPlantsAgain() async {
        let viewModel = AllPlantsViewModel(
            catalogService: TestPlantCatalog(),
            repository: InMemoryUserPlantRepository()
        )
        viewModel.selectedPage = .allPlants
        await viewModel.loadInitialData()

        let initialPlantCount = viewModel.filteredCatalogPlants.count
        #expect(initialPlantCount == 3)


        viewModel.searchText = "Monstera"

        let searchResultCount = viewModel.filteredCatalogPlants.count
        let firstSearchResultName = viewModel.filteredCatalogPlants.first?.commonName

        #expect(searchResultCount == 1)
        #expect(firstSearchResultName == "Swiss Cheese Plant")
        viewModel.searchText = ""

        let restoredPlantCount = viewModel.filteredCatalogPlants.count

        #expect(restoredPlantCount == 3)
    }

    @Test
    @MainActor
    func enrichmentRequestsRemoteDataOnlyAfterExplicitSearch() async throws {
        let remoteProvider = TrackingRemoteProvider()

        let service = CatalogEnrichmentService(remoteProvider: remoteProvider)
        let initialSearchCallCount = remoteProvider.searchCallCount
        #expect(initialSearchCallCount == 0)

        let results = try await service.searchPlants(matching: "Monstera")
        let finalSearchCallCount = remoteProvider.searchCallCount

        let receivedSearchQuery = remoteProvider.lastSearchQuery

        let remoteResultCount = results.count

        let firstRemoteResultName = results.first?.commonName

        #expect(finalSearchCallCount == 1)
        #expect(receivedSearchQuery == "Monstera")
        #expect(remoteResultCount == 1)
        #expect(firstRemoteResultName == "Remote Monstera")
    }

    @Test
    @MainActor
    func myPlantsSearchFiltersLoadedPlantsAndRestoresAll() async {
        let viewModel = AllPlantsViewModel(
            catalogService: TestPlantCatalog(),
            repository: InMemoryUserPlantRepository()
        )

        viewModel.selectedPage = .myPlants
        await viewModel.loadInitialData()

        let initialPlantCount = viewModel.filteredMyPlants.count

        viewModel.searchText = "Monstera"
        let matchingPlantNames = viewModel.filteredMyPlants.map { $0.name }
        #expect(matchingPlantNames == ["Monstera"])

        viewModel.searchText = ""
        let restoredPlantCount = viewModel.filteredMyPlants.count

        #expect(restoredPlantCount == initialPlantCount)
    }

    @Test
    @MainActor
    func manualAddRequiresPlantNameAndSpecies() {
        let repository = InMemoryUserPlantRepository()
        repository.mockPlants = []
        let viewModel = AddPlantViewModel(repository: repository)

        viewModel.name = "   "
        viewModel.speciesName = ""

        let didSave = viewModel.save()

        #expect(!didSave)
        #expect(
            viewModel.errorMessage
                == "Plant name and species are required."
        )
        #expect(repository.mockPlants.isEmpty)
    }

    @Test
    @MainActor
    func manualAddPersistsTrimmedPlantValues() {
        let calendar = makeTestCalendar()
        let referenceDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 20,
            using: calendar
        )
        let repository = InMemoryUserPlantRepository()
        repository.mockPlants = []
        let viewModel = AddPlantViewModel(
            repository: repository,
            now: { referenceDate }
        )

        viewModel.name = "  Bedroom Fern  "
        viewModel.speciesName = "  Nephrolepis exaltata  "
        viewModel.location = "  Bedroom  "
        viewModel.notes = "  Keep away from the radiator.  "
        viewModel.wateringIntervalDays = 4
        viewModel.fertilizingIntervalDays = 21

        let didSave = viewModel.save()
        let savedPlant = repository.mockPlants.first

        #expect(didSave)
        #expect(viewModel.errorMessage == nil)
        #expect(repository.mockPlants.count == 1)
        #expect(savedPlant?.name == "Bedroom Fern")
        #expect(savedPlant?.speciesName == "Nephrolepis exaltata")
        #expect(savedPlant?.location == "Bedroom")
        #expect(savedPlant?.notes == "Keep away from the radiator.")
        #expect(savedPlant?.lastWatered == referenceDate)
        #expect(savedPlant?.lastFertilized == referenceDate)
        #expect(savedPlant?.wateringIntervalDays == 4)
        #expect(savedPlant?.fertilizingIntervalDays == 21)
        #expect(savedPlant?.createdAt == referenceDate)
        #expect(savedPlant?.speciesInfo == nil)
    }

    @Test
    @MainActor
    func manualPlantDetailHidesCatalogOnlyConditions() {
        let referenceDate = Date()
        let manualPlant = makeTestPlant(
            name: "Bedroom Fern",
            lastWatered: referenceDate,
            wateringIntervalDays: 4
        )
        let catalogPlant = makeTestPlant(
            name: "Monstera",
            lastWatered: referenceDate,
            wateringIntervalDays: 7
        )
        catalogPlant.speciesInfo = PlantSpeciesInfo(
            from: makePlantSpecies(
                id: 1,
                commonName: "Swiss Cheese Plant",
                scientificName: "Monstera deliciosa"
            )
        )
        let repository = InMemoryUserPlantRepository()

        let manualViewModel = PlantDetailViewModel(
            plant: manualPlant,
            repository: repository,
            plantSpeciesProvider: nil
        )
        let catalogViewModel = PlantDetailViewModel(
            plant: catalogPlant,
            repository: repository,
            plantSpeciesProvider: nil
        )

        #expect(!manualViewModel.hasSpeciesConditions)
        #expect(catalogViewModel.hasSpeciesConditions)
    }

    @Test
    @MainActor
    func fertilizingScheduleUsesLastFertilizedDate() {
        let calendar = makeTestCalendar()
        let lastFertilized = makeTestDate(
            year: 2026,
            month: 8,
            day: 1,
            using: calendar
        )
        let referenceDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 20,
            using: calendar
        )
        let expectedDueDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 22,
            using: calendar
        )
        let plant = makeTestPlant(
            name: "Bedroom Fern",
            lastWatered: referenceDate,
            wateringIntervalDays: 4
        )
        plant.lastFertilized = lastFertilized
        plant.fertilizingIntervalDays = 21

        #expect(plant.nextFertilizingDate(using: calendar) == expectedDueDate)
        #expect(
            plant.daysUntilNextFertilizing(
                using: calendar,
                referenceDate: referenceDate
            ) == 2
        )
    }

    @Test
    @MainActor
    func wateringTaskUsesPlantScheduleForDueStatus() {
        let calendar = makeTestCalendar()
        let lastWatered = makeTestDate(
            year: 2026,
            month: 8,
            day: 15,
            using: calendar
        )
        let expectedDueDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 18,
            using: calendar
        )
        let dayBeforeDueDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 17,
            using: calendar
        )
        let dayAfterDueDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 19,
            using: calendar
        )
        let plant = makeTestPlant(
            name: "Monstera",
            lastWatered: lastWatered,
            wateringIntervalDays: 3
        )

        let task = CareTask.watering(
            for: plant,
            using: calendar
        )
        let daysBeforeDueDate = task.daysUntilDue(
            referenceDate: dayBeforeDueDate,
            using: calendar
        )
        let daysAfterDueDate = task.daysUntilDue(
            referenceDate: dayAfterDueDate,
            using: calendar
        )
        let isOverdueAfterDueDate = task.isOverdue(
            referenceDate: dayAfterDueDate,
            using: calendar
        )

        #expect(task.dueDate == expectedDueDate)
        #expect(daysBeforeDueDate == 1)
        #expect(daysAfterDueDate == -1)
        #expect(isOverdueAfterDueDate)
    }

    @Test
    @MainActor
    func todayTasksIncludeOverdueAndDueTodayOnly() async {
        let calendar = makeTestCalendar()
        let referenceDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 18,
            using: calendar
        )
        let repository = InMemoryUserPlantRepository()
        repository.mockPlants = [
            makeTestPlant(
                name: "Overdue",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 14,
                    using: calendar
                ),
                wateringIntervalDays: 3
            ),
            makeTestPlant(
                name: "Due Today",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 15,
                    using: calendar
                ),
                wateringIntervalDays: 3
            ),
            makeTestPlant(
                name: "Due Tomorrow",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 16,
                    using: calendar
                ),
                wateringIntervalDays: 3
            )
        ]
        let viewModel = CareTasksViewModel(
            repository: repository,
            careEventRepository: InMemoryCareEventRepository(),
            calendar: calendar,
            now: { referenceDate }
        )

        await viewModel.loadTasks()

        let todayTaskNames = viewModel.todayTasks.map { $0.plant.name }

        #expect(todayTaskNames == ["Overdue", "Due Today"])
    }

    @Test
    @MainActor
    func careEventLoadFailureKeepsOpenTasksVisible() async {
        let calendar = makeTestCalendar()
        let referenceDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 18,
            using: calendar
        )
        let repository = InMemoryUserPlantRepository()
        let careEventRepository = ControlledCareEventRepository()

        repository.mockPlants = [
            makeTestPlant(
                name: "Due Today",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 15,
                    using: calendar
                ),
                wateringIntervalDays: 3
            )
        ]
        careEventRepository.shouldFailFetching = true

        let viewModel = CareTasksViewModel(
            repository: repository,
            careEventRepository: careEventRepository,
            calendar: calendar,
            now: { referenceDate }
        )

        await viewModel.loadTasks()

        #expect(viewModel.todayTasks.map { $0.plant.name } == ["Due Today"])
        #expect(
            viewModel.errorMessage
                == "Completed care tasks could not be loaded."
        )
    }

    @Test
    @MainActor
    func weeklyCareScheduleStartsMondayAndMarksWateringDays() async {
        let calendar = makeTestCalendar()
        let referenceDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 18,
            using: calendar
        )
        let monday = makeTestDate(
            year: 2026,
            month: 8,
            day: 17,
            using: calendar
        )
        let sunday = makeTestDate(
            year: 2026,
            month: 8,
            day: 23,
            using: calendar
        )

        let repository = InMemoryUserPlantRepository()
        repository.mockPlants = [
            makeTestPlant(
                name: "Due Thursday",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 17,
                    using: calendar
                ),
                wateringIntervalDays: 3
            ),
            makeTestPlant(
                name: "Due Sunday",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 20,
                    using: calendar
                ),
                wateringIntervalDays: 3
            ),
            makeTestPlant(
                name: "Due Next Week",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 21,
                    using: calendar
                ),
                wateringIntervalDays: 3
            )
        ]

        let viewModel = CareTasksViewModel(
            repository: repository,
            careEventRepository: InMemoryCareEventRepository(),
            calendar: calendar,
            now: { referenceDate }
        )

        await viewModel.loadTasks()

        let weekDays = viewModel.weekDays
        let markedDayNumbers = weekDays
            .filter(\.hasWateringTask)
            .map {
                calendar.component(
                    .day,
                    from: $0.date
                )
            }
        let todayDayNumbers = weekDays
            .filter(\.isToday)
            .map {
                calendar.component(
                    .day,
                    from: $0.date
                )
            }

        #expect(weekDays.count == 7)

        if let firstDate = weekDays.first?.date {
            #expect(
                calendar.isDate(
                    firstDate,
                    inSameDayAs: monday
                )
            )
        } else {
            Issue.record("The weekly schedule has no first day.")
        }

        if let lastDate = weekDays.last?.date {
            #expect(
                calendar.isDate(
                    lastDate,
                    inSameDayAs: sunday
                )
            )
        } else {
            Issue.record("The weekly schedule has no last day.")
        }

        #expect(markedDayNumbers == [20, 23])
        #expect(todayDayNumbers == [18])
    }

    @Test
    @MainActor
    func completingTodayTaskKeepsItVisibleAsCompleted() async {
        let calendar = makeTestCalendar()
        let referenceDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 18,
            using: calendar
        )
        let repository = InMemoryUserPlantRepository()
        let careEventRepository = InMemoryCareEventRepository()

        repository.mockPlants = [
            makeTestPlant(
                name: "Due Today",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 15,
                    using: calendar
                ),
                wateringIntervalDays: 3
            )
        ]

        let initialViewModel = CareTasksViewModel(
            repository: repository,
            careEventRepository: careEventRepository,
            calendar: calendar,
            now: { referenceDate }
        )
        await initialViewModel.loadTasks()
        guard let task = initialViewModel.todayTasks.first else {
            Issue.record("The expected task due today is missing.")
            return
        }

        await initialViewModel.complete(task)
        let reloadedViewModel = CareTasksViewModel(
            repository: repository,
            careEventRepository: careEventRepository,
            calendar: calendar,
            now: { referenceDate }
        )

        await reloadedViewModel.loadTasks()
        let todayTasks = reloadedViewModel.todayTasks
        let completedTaskNames = todayTasks
            .filter(\.isCompleted)
            .map { $0.plant.name }
        let completedDueDay = reloadedViewModel.weekDays.first {
            calendar.isDate(
                $0.date,
                inSameDayAs: task.dueDate
            )
        }

        #expect(careEventRepository.mockEvents.count == 1)
        #expect(todayTasks.count == 1)
        #expect(completedTaskNames == ["Due Today"])
        #expect(completedDueDay?.hasWateringTask == true)
    }

    @Test
    @MainActor
    func completionKeepsCareEventReloadErrorVisible() async {
        let calendar = makeTestCalendar()
        let referenceDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 18,
            using: calendar
        )
        let repository = InMemoryUserPlantRepository()
        let careEventRepository = ControlledCareEventRepository()

        repository.mockPlants = [
            makeTestPlant(
                name: "Due Today",
                lastWatered: makeTestDate(
                    year: 2026,
                    month: 8,
                    day: 15,
                    using: calendar
                ),
                wateringIntervalDays: 3
            )
        ]

        let viewModel = CareTasksViewModel(
            repository: repository,
            careEventRepository: careEventRepository,
            calendar: calendar,
            now: { referenceDate }
        )

        await viewModel.loadTasks()

        guard let task = viewModel.todayTasks.first else {
            Issue.record("The expected task due today is missing.")
            return
        }

        careEventRepository.shouldFailFetching = true
        await viewModel.complete(task)

        #expect(
            viewModel.errorMessage
                == "Completed care tasks could not be loaded."
        )
    }

    @Test
    @MainActor
    func wateringCompletionPersistsCareEventAndUpdatesPlant() throws {
        let calendar = makeTestCalendar()
        let lastWatered = makeTestDate(
            year: 2026,
            month: 8,
            day: 15,
            using: calendar
        )
        let dueDate = makeTestDate(
            year: 2026,
            month: 8,
            day: 18,
            using: calendar
        )
        let completedAt = makeTestDate(
            year: 2026,
            month: 8,
            day: 19,
            using: calendar
        )

        let schema = Schema([
            Plant.self,
            PlantSpeciesInfo.self,
            CareEvent.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        let plantRepository = SwiftDataUserPlantRepository(
            modelContext: container.mainContext
        )
        let careEventRepository = SwiftDataCareEventRepository(
            modelContext: container.mainContext
        )
        let plant = makeTestPlant(
            name: "Monstera",
            lastWatered: lastWatered,
            wateringIntervalDays: 3
        )

        try plantRepository.savePlant(plant)

        let event = try careEventRepository.recordWateringCompletion(
            for: plant,
            dueDate: dueDate,
            completedAt: completedAt
        )
        let storedEvents = try careEventRepository.fetchAllEvents()

        #expect(plant.lastWatered == completedAt)
        #expect(storedEvents.count == 1)
        #expect(storedEvents.first?.id == event.id)
        #expect(storedEvents.first?.plantID == plant.id)
        #expect(storedEvents.first?.plantName == "Monstera")
        #expect(storedEvents.first?.kind == CareKind.watering)
        #expect(storedEvents.first?.dueDate == dueDate)
        #expect(storedEvents.first?.completedAt == completedAt)
    }
}

private struct TestPlantCatalog: PlantCatalogRepository {
    private let plants = [
        makePlantSpecies(
            id: 1,
            commonName: "Swiss Cheese Plant",
            scientificName: "Monstera deliciosa"
        ),
        makePlantSpecies(
            id: 2,
            commonName: "Snake Plant",
            scientificName: "Dracaena trifasciata"
        ),
        makePlantSpecies(
            id: 3,
            commonName: "Golden Pothos",
            scientificName: "Epipremnum aureum"
        ),
    ]

    func searchPlants(matching query: String) async throws -> [PlantSpecies] {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else {
            return plants
        }

        return plants.filter { plant in
            plant.commonName.localizedCaseInsensitiveContains(trimmedQuery)
            || plant.scientificName.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    func getPlantDetail(id: Int) async throws -> PlantSpecies {
        guard let plant = plants.first(
            where: { $0.speciesId == id }
        ) else {
            throw LocalPlantCatalogError.plantNotFound
        }
        return plant
    }
}

private final class TrackingRemoteProvider: PlantSpeciesProvider {
    private(set) var searchCallCount = 0
    private(set) var lastSearchQuery: String?

    func searchPlants(
        matching query: String
    ) async throws -> [PlantSpecies] {
        searchCallCount += 1
        lastSearchQuery = query

        return [
            makePlantSpecies(
                id: 100,
                commonName: "Remote Monstera",
                scientificName: "Monstera deliciosa"
            )
        ]
    }

    func getPlantDetail(
        id: Int
    ) async throws -> PlantSpecies {
        makePlantSpecies(
            id: id,
            commonName: "Remote Monstera",
            scientificName: "Monstera deliciosa"
        )
    }
}

// Allows error-path tests to fail event loading without replacing repository behavior.
@MainActor
private final class ControlledCareEventRepository: CareEventRepository {
    private enum TestError: Error {
        case fetchFailed
    }

    private let storage = InMemoryCareEventRepository()
    var shouldFailFetching = false

    func fetchAllEvents() throws -> [CareEvent] {
        if shouldFailFetching {
            throw TestError.fetchFailed
        }

        return try storage.fetchAllEvents()
    }

    func recordWateringCompletion(
        for plant: Plant,
        dueDate: Date,
        completedAt: Date
    ) throws -> CareEvent {
        try storage.recordWateringCompletion(
            for: plant,
            dueDate: dueDate,
            completedAt: completedAt
        )
    }
}

private func makePlantSpecies(
    id: Int,
    commonName: String,
    scientificName: String
) -> PlantSpecies {
    PlantSpecies(
        speciesId: id,
        commonName: commonName,
        scientificName: scientificName,
        watering: nil,
        wateringFrequency: nil,
        sunlight: nil,
        maintenance: nil,
        indoor: true,
        imageUrl: nil,
        careLevel: nil,
        description: nil
    )
}

private func makeTestCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}

private func makeTestDate(
    year: Int,
    month: Int,
    day: Int,
    using calendar: Calendar
) -> Date {
    calendar.date(
        from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: 12
        )
    )!
}

@MainActor
private func makeTestPlant(
    name: String,
    lastWatered: Date,
    wateringIntervalDays: Int
) -> Plant {
    Plant(
        name: name,
        speciesName: "Test species",
        lastWatered: lastWatered,
        lastFertilized: lastWatered,
        wateringIntervalDays: wateringIntervalDays,
        fertilizingIntervalDays: 30,
        createdAt: lastWatered
    )
}
