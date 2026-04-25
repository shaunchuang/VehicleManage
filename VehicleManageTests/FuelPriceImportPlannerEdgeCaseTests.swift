//
//  FuelPriceImportPlannerEdgeCaseTests.swift
//  VehicleManageTests
//

import Testing
@testable import VehicleManage

import Foundation

struct FuelPriceImportPlannerEdgeCaseTests {

    // MARK: - Empty inputs

    @Test func plan_bothEmpty_returnsEmptyPlan() {
        let plan = FuelPriceImportPlanner.plan(apiSnapshots: [], existingSnapshots: [])
        #expect(plan.inserts.isEmpty)
        #expect(plan.updates.isEmpty)
        #expect(plan.duplicateDates.isEmpty)
    }

    @Test func plan_emptyAPI_noChanges() {
        let date = Date(timeIntervalSince1970: 1_000)
        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [],
            existingSnapshots: [FuelPriceSnapshot(effectiveDate: date, price: 30.0)]
        )
        #expect(plan.inserts.isEmpty)
        #expect(plan.updates.isEmpty)
        #expect(plan.duplicateDates.isEmpty)
    }

    // MARK: - All new (inserts only)

    @Test func plan_allNewSnapshots_allInserted() {
        let dates = (0..<3).map { Date(timeIntervalSince1970: Double($0) * 1_000) }
        let apiSnapshots = dates.map { FuelPriceSnapshot(effectiveDate: $0, price: 30.0) }

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: apiSnapshots,
            existingSnapshots: []
        )

        #expect(plan.inserts.count == 3)
        #expect(plan.updates.isEmpty)
        #expect(plan.duplicateDates.isEmpty)
    }

    // MARK: - Exact match (no changes)

    @Test func plan_sameSnapshotExists_producesNoChange() {
        let date = Date(timeIntervalSince1970: 5_000)
        let snapshot = FuelPriceSnapshot(effectiveDate: date, price: 30.5)

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [snapshot],
            existingSnapshots: [snapshot]
        )

        #expect(plan.inserts.isEmpty)
        #expect(plan.updates.isEmpty)
        #expect(plan.duplicateDates.isEmpty)
    }

    // MARK: - Multiple updates

    @Test func plan_multipleChangedPrices_allUpdated() {
        let date1 = Date(timeIntervalSince1970: 1_000)
        let date2 = Date(timeIntervalSince1970: 2_000)

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [
                FuelPriceSnapshot(effectiveDate: date1, price: 31.0),
                FuelPriceSnapshot(effectiveDate: date2, price: 32.0),
            ],
            existingSnapshots: [
                FuelPriceSnapshot(effectiveDate: date1, price: 30.0),
                FuelPriceSnapshot(effectiveDate: date2, price: 30.0),
            ]
        )

        #expect(plan.inserts.isEmpty)
        #expect(plan.updates.count == 2)
        #expect(plan.duplicateDates.isEmpty)
    }

    // MARK: - Mixed inserts and updates

    @Test func plan_mixedInsertsAndUpdates() {
        let existingDate = Date(timeIntervalSince1970: 1_000)
        let newDate = Date(timeIntervalSince1970: 2_000)

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [
                FuelPriceSnapshot(effectiveDate: existingDate, price: 31.0),
                FuelPriceSnapshot(effectiveDate: newDate, price: 32.0),
            ],
            existingSnapshots: [
                FuelPriceSnapshot(effectiveDate: existingDate, price: 30.0)
            ]
        )

        #expect(plan.inserts.count == 1)
        #expect(plan.inserts[0].effectiveDate == newDate)
        #expect(plan.updates.count == 1)
        #expect(plan.updates[0].effectiveDate == existingDate)
        #expect(plan.duplicateDates.isEmpty)
    }

    // MARK: - Multiple duplicate dates

    @Test func plan_multipleDuplicateDates_allReported() {
        let date1 = Date(timeIntervalSince1970: 1_000)
        let date2 = Date(timeIntervalSince1970: 2_000)

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [
                FuelPriceSnapshot(effectiveDate: date1, price: 30.0),
                FuelPriceSnapshot(effectiveDate: date2, price: 31.0),
            ],
            existingSnapshots: [
                FuelPriceSnapshot(effectiveDate: date1, price: 30.0),
                FuelPriceSnapshot(effectiveDate: date1, price: 30.0),
                FuelPriceSnapshot(effectiveDate: date2, price: 31.0),
                FuelPriceSnapshot(effectiveDate: date2, price: 31.0),
            ]
        )

        #expect(plan.inserts.isEmpty)
        #expect(plan.updates.isEmpty)
        #expect(plan.duplicateDates.count == 2)
        #expect(plan.duplicateDates.contains(date1))
        #expect(plan.duplicateDates.contains(date2))
    }

    // MARK: - Duplicate API snapshots for the same date use the latest

    @Test func plan_duplicateAPISnapshotsForSameDate_lastOneWins() {
        let date = Date(timeIntervalSince1970: 1_000)

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [
                FuelPriceSnapshot(effectiveDate: date, price: 30.0),
                FuelPriceSnapshot(effectiveDate: date, price: 31.0),
            ],
            existingSnapshots: []
        )

        // De-duplicated → only one insert; the price must be the last one passed
        // (Dictionary(uniquingKeysWith:) picks the second).
        #expect(plan.inserts.count == 1)
        #expect(plan.inserts[0].effectiveDate == date)
    }
}
