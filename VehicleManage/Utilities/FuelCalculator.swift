import Foundation

/// Pure, stateless helpers for fuel economy and cost calculations.
/// These functions operate on scalar values and have no SwiftData
/// dependencies, making them straightforward to unit-test.
enum FuelCalculator {

    /// Distance driven between two odometer readings.
    /// Returns 0 when `nextMileage` ≤ `currentMileage`.
    static func drivenDistance(from currentMileage: Double, to nextMileage: Double) -> Double {
        let d = nextMileage - currentMileage
        return d > 0 ? d : 0
    }

    /// Fuel economy in km/L. Returns 0 when `fuelAmount` ≤ 0.
    static func fuelEconomy(distance: Double, fuelAmount: Double) -> Double {
        guard fuelAmount > 0 else { return 0 }
        return distance / fuelAmount
    }

    /// Operating cost per km. Returns 0 when `distance` ≤ 0.
    static func costPerKm(cost: Double, distance: Double) -> Double {
        guard distance > 0 else { return 0 }
        return cost / distance
    }

    /// Estimated total cost for a fill-up given a unit price.
    static func estimatedCost(fuelAmount: Double, unitPrice: Double) -> Double {
        fuelAmount * unitPrice
    }

    /// Overall average fuel economy using the mileage spread and total
    /// fuel across a range, which is more accurate than averaging
    /// individual per-fill-up km/L values.
    static func overallAverageConsumption(totalDistance: Double, totalFuel: Double) -> Double {
        guard totalFuel > 0 else { return 0 }
        return totalDistance / totalFuel
    }

    /// Average cost per km across a range.
    static func averageCostPerKm(totalCost: Double, totalDistance: Double) -> Double {
        guard totalDistance > 0 else { return 0 }
        return totalCost / totalDistance
    }
}
