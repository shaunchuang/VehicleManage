// VehicleStatsProvider.swift
import WidgetKit

struct VehicleStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> FuelEntry {
        FuelEntry(
            date: Date(),
            fuelPrices: ["98無鉛": 34.0, "95無鉛": 32.0, "92無鉛": 30.5, "柴油": 29.5],
            averageFuelConsumption: 15.2,
            totalMileage: 12345.6,
            defaultFuelType: .gas95,
            mode: context.family == .systemLarge ? .combined : .defaultFuelAndStats,
            vehicleName: "My Car",
            vehicleType: "car.fill"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FuelEntry) -> Void) {
        let mode: DisplayMode = context.family == .systemLarge ? .combined : .defaultFuelAndStats
        completion(entryFromCache(mode: mode) ?? FuelEntry(
            date: Date(),
            fuelPrices: ["98無鉛": 34.0, "95無鉛": 32.0, "92無鉛": 30.5, "柴油": 29.5],
            averageFuelConsumption: 15.2,
            totalMileage: 12345.6,
            defaultFuelType: .gas95,
            mode: mode,
            vehicleName: "My Car",
            vehicleType: "car.fill"
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FuelEntry>) -> Void) {
        let mode: DisplayMode = context.family == .systemLarge ? .combined : .defaultFuelAndStats
        let entry = entryFromCache(mode: mode) ?? FuelEntry(
            date: Date(),
            fuelPrices: [:],
            averageFuelConsumption: 0,
            totalMileage: 0,
            defaultFuelType: .gas95,
            mode: mode
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Private

    private func entryFromCache(mode: DisplayMode) -> FuelEntry? {
        guard let cache = WidgetDataCache.load() else { return nil }

        let futureFuelPrices = cache.futureFuelPrices.mapValues { cached in
            (price: cached.price, difference: cached.difference)
        }

        return FuelEntry(
            date: cache.updatedAt,
            fuelPrices: cache.fuelPrices,
            futureFuelPrices: futureFuelPrices,
            averageFuelConsumption: cache.averageFuelConsumption,
            totalMileage: cache.totalMileage,
            defaultFuelType: FuelType(rawValue: cache.defaultFuelType) ?? .gas95,
            mode: mode,
            recordCount: cache.recordCount,
            totalCost: cache.totalCost,
            totalFuelAmount: cache.totalFuelAmount,
            rangeMileage: cache.rangeMileage,
            maxConsumption: cache.maxConsumption,
            minConsumption: cache.minConsumption,
            costPerKm: cache.costPerKm,
            vehicleName: cache.vehicleName,
            vehicleType: cache.vehicleType
        )
    }
}
