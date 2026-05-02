// FuelConsumptionProvider.swift
import WidgetKit

struct FuelConsumptionProvider: TimelineProvider {
    func placeholder(in context: Context) -> FuelEntry {
        FuelEntry(
            date: Date(),
            fuelPrices: ["98無鉛": 34.0, "95無鉛": 32.0, "92無鉛": 30.5, "柴油": 29.5],
            averageFuelConsumption: 15.2,
            totalMileage: 12345.6,
            defaultFuelType: .gas95,
            mode: .allFuelPrices
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FuelEntry) -> Void) {
        completion(entryFromCache() ?? FuelEntry(
            date: Date(),
            fuelPrices: ["98無鉛": 34.0, "95無鉛": 32.0, "92無鉛": 30.5, "柴油": 29.5],
            averageFuelConsumption: 15.2,
            totalMileage: 12345.6,
            defaultFuelType: .gas95,
            mode: .allFuelPrices
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FuelEntry>) -> Void) {
        let entry = entryFromCache() ?? FuelEntry(
            date: Date(),
            fuelPrices: [:],
            averageFuelConsumption: 0,
            totalMileage: 0,
            defaultFuelType: .gas95,
            mode: .allFuelPrices
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Private

    private func entryFromCache() -> FuelEntry? {
        guard let cache = WidgetDataCache.load() else { return nil }

        let futureFuelPrices = cache.futureFuelPrices.mapValues { cached in
            (price: cached.price, difference: cached.difference)
        }

        return FuelEntry(
            date: cache.updatedAt,
            fuelPrices: cache.fuelPrices,
            futureFuelPrices: futureFuelPrices,
            averageFuelConsumption: 0,
            totalMileage: 0,
            defaultFuelType: FuelType(rawValue: cache.defaultFuelType) ?? .gas95,
            mode: .allFuelPrices
        )
    }
}
