// WidgetDataCache.swift
// VehicleManage
//
// Shared cache written by the main app and read by the widget extension.
// Stored as JSON in the App Group UserDefaults so the widget can read it
// without opening a SwiftData container directly.

import Foundation

// MARK: - Cache model

/// Snapshot of data the widget needs, serialised to App Group UserDefaults.
struct WidgetCache: Codable {
    var vehicleName: String = "未知車輛"
    var vehicleType: String = "car.fill"        // SF Symbol name
    var defaultFuelType: String = FuelType.gas95.rawValue
    var totalMileage: Double = 0
    var averageFuelConsumption: Double = 0
    var recordCount: Int = 0
    var totalCost: Double = 0
    var totalFuelAmount: Double = 0
    var rangeMileage: Double = 0
    var maxConsumption: Double = 0
    var minConsumption: Double = 0
    var costPerKm: Double = 0
    var fuelPrices: [String: Double] = [:]
    var futureFuelPrices: [String: CachedFutureFuelPrice] = [:]
    var updatedAt: Date = Date()

    struct CachedFutureFuelPrice: Codable {
        var price: Double
        var difference: Double
    }
}

// MARK: - Cache storage helpers

enum WidgetDataCache {
    static let userDefaultsKey = "widgetCache"
    static let suiteName = "group.ShaunChuang.VehicleManage"

    /// Returns the current cached snapshot, or nil if none exists yet.
    static func load() -> WidgetCache? {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetCache.self, from: data)
    }

    /// Persists the snapshot to App Group UserDefaults.
    static func save(_ cache: WidgetCache) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        UserDefaults(suiteName: suiteName)?.set(data, forKey: userDefaultsKey)
    }
}
