//
//  VehicleManageTests.swift
//  VehicleManageTests
//
//  Created by Shaun Chuang on 2025/2/15.
//

import Testing
import Foundation
@testable import VehicleManage

struct VehicleManageTests {

    // MARK: - FuelCalculator: drivenDistance

    @Test func drivenDistance_positiveReturnsDistance() {
        #expect(FuelCalculator.drivenDistance(from: 1000, to: 1100) == 100)
    }

    @Test func drivenDistance_reverseOrderReturnsZero() {
        #expect(FuelCalculator.drivenDistance(from: 1100, to: 1000) == 0)
    }

    @Test func drivenDistance_equalMileageReturnsZero() {
        #expect(FuelCalculator.drivenDistance(from: 1000, to: 1000) == 0)
    }

    // MARK: - FuelCalculator: fuelEconomy

    @Test func fuelEconomy_normalValues() {
        #expect(FuelCalculator.fuelEconomy(distance: 200, fuelAmount: 20) == 10.0)
    }

    @Test func fuelEconomy_zeroFuelReturnsZero() {
        #expect(FuelCalculator.fuelEconomy(distance: 200, fuelAmount: 0) == 0)
    }

    @Test func fuelEconomy_zeroDistance() {
        #expect(FuelCalculator.fuelEconomy(distance: 0, fuelAmount: 20) == 0)
    }

    // MARK: - FuelCalculator: costPerKm

    @Test func costPerKm_normalValues() {
        #expect(FuelCalculator.costPerKm(cost: 1000, distance: 100) == 10.0)
    }

    @Test func costPerKm_zeroDistanceReturnsZero() {
        #expect(FuelCalculator.costPerKm(cost: 1000, distance: 0) == 0)
    }

    // MARK: - FuelCalculator: estimatedCost

    @Test func estimatedCost_normalValues() {
        #expect(FuelCalculator.estimatedCost(fuelAmount: 30, unitPrice: 32.5) == 975.0)
    }

    @Test func estimatedCost_zeroFuel() {
        #expect(FuelCalculator.estimatedCost(fuelAmount: 0, unitPrice: 32.5) == 0)
    }

    // MARK: - FuelRecord

    @Test func fuelRecord_roundsFuelAmountToTwoDecimalPlaces() {
        #expect(FuelRecord.roundedFuelAmount(12.345) == 12.35)
        #expect(FuelRecord.roundedFuelAmount(12.344) == 12.34)
    }

    // MARK: - FuelCalculator: overallAverageConsumption

    @Test func overallAverageConsumption_normalValues() {
        #expect(FuelCalculator.overallAverageConsumption(totalDistance: 500, totalFuel: 50) == 10.0)
    }

    @Test func overallAverageConsumption_zeroFuelReturnsZero() {
        #expect(FuelCalculator.overallAverageConsumption(totalDistance: 500, totalFuel: 0) == 0)
    }

    // MARK: - FuelCalculator: averageCostPerKm

    @Test func averageCostPerKm_normalValues() {
        #expect(FuelCalculator.averageCostPerKm(totalCost: 2000, totalDistance: 400) == 5.0)
    }

    @Test func averageCostPerKm_zeroDistanceReturnsZero() {
        #expect(FuelCalculator.averageCostPerKm(totalCost: 2000, totalDistance: 0) == 0)
    }

    // MARK: - FuelPriceImportPlanner

    @Test func fuelPriceImportPlanner_insertsOnlyMissingDates() {
        let oldDate = Date(timeIntervalSince1970: 1_000)
        let newDate = Date(timeIntervalSince1970: 2_000)

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [
                FuelPriceSnapshot(effectiveDate: oldDate, price: 31.2),
                FuelPriceSnapshot(effectiveDate: newDate, price: 32.0),
            ],
            existingSnapshots: [
                FuelPriceSnapshot(effectiveDate: oldDate, price: 31.2)
            ]
        )

        #expect(plan.inserts == [FuelPriceSnapshot(effectiveDate: newDate, price: 32.0)])
        #expect(plan.updates.isEmpty)
        #expect(plan.duplicateDates.isEmpty)
    }

    @Test func fuelPriceImportPlanner_updatesChangedPriceForExistingDate() {
        let effectiveDate = Date(timeIntervalSince1970: 3_000)

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [
                FuelPriceSnapshot(effectiveDate: effectiveDate, price: 32.1)
            ],
            existingSnapshots: [
                FuelPriceSnapshot(effectiveDate: effectiveDate, price: 31.8)
            ]
        )

        #expect(plan.inserts.isEmpty)
        #expect(plan.updates == [FuelPriceSnapshot(effectiveDate: effectiveDate, price: 32.1)])
        #expect(plan.duplicateDates.isEmpty)
    }

    @Test func fuelPriceImportPlanner_detectsDuplicateStoredDates() {
        let duplicateDate = Date(timeIntervalSince1970: 4_000)

        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: [
                FuelPriceSnapshot(effectiveDate: duplicateDate, price: 30.5)
            ],
            existingSnapshots: [
                FuelPriceSnapshot(effectiveDate: duplicateDate, price: 30.5),
                FuelPriceSnapshot(effectiveDate: duplicateDate, price: 30.5),
            ]
        )

        #expect(plan.inserts.isEmpty)
        #expect(plan.updates.isEmpty)
        #expect(plan.duplicateDates == [duplicateDate])
    }
}
