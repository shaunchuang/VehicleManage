//
//  VehicleManageTests.swift
//  VehicleManageTests
//
//  Created by Shaun Chuang on 2025/2/15.
//

import Testing
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
}
