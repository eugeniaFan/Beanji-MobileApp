//
//  BeanjiUITests.swift
//  BeanjiUITests
//
//  Created by Eugenia Fanenstiel on 14.08.26.
//

import XCTest

final class BeanjiUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCanAddManualPlant() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launch()

        let plantsTab = app.tabBars.buttons["Plants"]
        XCTAssertTrue(
            plantsTab.waitForExistence(timeout: 5),
            "The Plants tab should be available after launch."
        )
        plantsTab.tap()

        let newPlantButton = app.buttons["New Plant"]
        XCTAssertTrue(
            newPlantButton.waitForExistence(timeout: 5),
            "The New Plant button should be visible on My Plants."
        )
        newPlantButton.tap()

        let addPlantNavigationBar = app.navigationBars["Add Plant"]
        XCTAssertTrue(
            addPlantNavigationBar.waitForExistence(timeout: 5),
            "The Add Plant form should open."
        )

        let plantNameField = app.textFields["Plant name"]
        XCTAssertTrue(
            plantNameField.exists,
            "The plant name field should be visible."
        )
        plantNameField.tap()
        plantNameField.typeText("Cherry")

        let speciesNameField = app.textFields["Species name"]
        XCTAssertTrue(
            speciesNameField.exists,
            "The species name field should be visible."
        )
        speciesNameField.tap()
        speciesNameField.typeText("Tomato")

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(
            saveButton.isEnabled,
            "Save should be enabled after entering both required names."
        )
        saveButton.tap()

        XCTAssertTrue(
            app.staticTexts["Cherry"].waitForExistence(timeout: 5),
            "The saved plant should appear in My Plants."
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
