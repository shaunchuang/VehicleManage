// WidgetCacheUpdater.swift
// VehicleManage
//
// Computes the WidgetCache from live SwiftData models and saves it to
// App Group UserDefaults.  Only compiled into the main app target.

import Foundation
import SwiftData

enum WidgetCacheUpdater {
    /// Reads the default Vehicle's stats and the latest CPC fuel prices from
    /// `context`, builds a `WidgetCache`, and saves it to App Group UserDefaults.
    /// Must be called on the main actor because SwiftData's ModelContext is
    /// main-actor-bound.
    @MainActor
    static func update(from context: ModelContext) {
        do {
            var cache = WidgetCache()

            // ── Default vehicle stats ──────────────────────────────────────
            let vehicleDescriptor = FetchDescriptor<Vehicle>(
                predicate: #Predicate { $0.isDefault == true }
            )
            if let defaultVehicle = try context.fetch(vehicleDescriptor).first {
                cache.vehicleName = defaultVehicle.name
                cache.vehicleType = defaultVehicle.vehicleType == .car ? "car.fill" : "motorcycle"
                cache.defaultFuelType = defaultVehicle.defaultFuelType.rawValue

                let sorted = defaultVehicle.fuelRecords.sorted { $0.date < $1.date }
                if !sorted.isEmpty {
                    cache.recordCount = sorted.count
                    cache.totalCost = sorted.reduce(0) { $0 + $1.cost }
                    cache.totalFuelAmount = sorted.reduce(0) { $0 + $1.fuelAmount }
                    cache.totalMileage = sorted.last?.mileage ?? 0
                    cache.rangeMileage = cache.totalMileage - (sorted.first?.mileage ?? 0)
                    let valid = sorted.filter { $0.averageFuelConsumption > 0 }.map { $0.averageFuelConsumption }
                    cache.maxConsumption = valid.max() ?? 0
                    cache.minConsumption = valid.min() ?? 0
                    cache.averageFuelConsumption = cache.rangeMileage > 0 && cache.totalFuelAmount > 0
                        ? cache.rangeMileage / cache.totalFuelAmount
                        : 0
                    cache.costPerKm = cache.rangeMileage > 0 ? cache.totalCost / cache.rangeMileage : 0
                }
            }

            // ── Current and future fuel prices ────────────────────────────
            let now = Date()
            for name in FuelType.allCPCProductNames {
                let descriptor = FetchDescriptor<CPCFuelPriceModel>(
                    predicate: #Predicate { $0.productName == name },
                    sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
                )
                let results = try context.fetch(descriptor)
                guard let current = results.first(where: { $0.effectiveDate <= now }),
                      let fuelType = FuelType.fromCPCProductName(name)
                else { continue }
                let displayName = fuelType.rawValue
                cache.fuelPrices[displayName] = current.price
                if let future = results.first(where: { $0.effectiveDate > now }) {
                    cache.futureFuelPrices[displayName] = .init(
                        price: future.price,
                        difference: future.price - current.price
                    )
                }
            }

            cache.updatedAt = Date()
            WidgetDataCache.save(cache)
        } catch {
            print("WidgetCacheUpdater: 更新快取失敗：\(error)")
        }
    }
}
