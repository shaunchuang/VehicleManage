// VehicleStatsProvider.swift
import WidgetKit
import SwiftData

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
        let entry = FuelEntry(
            date: Date(),
            fuelPrices: ["98無鉛": 34.0, "95無鉛": 32.0, "92無鉛": 30.5, "柴油": 29.5],
            averageFuelConsumption: 15.2,
            totalMileage: 12345.6,
            defaultFuelType: .gas95,
            mode: mode,
            vehicleName: "My Car",
            vehicleType: "car.fill"
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FuelEntry>) -> Void) {
        Task {
            var fuelPricesDict: [String: Double] = [:]
            var futureFuelPricesDict: [String: (price: Double, difference: Double)] = [:]
            var avgFuelConsumption: Double = 0.0
            var totalMileage: Double = 0.0
            var defaultFuelType: FuelType = .gas95
            var recordCount: Int = 0
            var totalCost: Double = 0.0
            var totalFuelAmount: Double = 0.0
            var rangeMileage: Double = 0.0
            var maxConsumption: Double = 0.0
            var minConsumption: Double = 0.0
            var costPerKm: Double = 0.0
            var vehicleName: String = "未知車輛"
            var vehicleType: String = "car.fill"
            
            do {
                guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ShaunChuang.VehicleManage") else {
                    print("無法獲取 App Group 路徑")
                    let entry = FuelEntry(date: Date(), fuelPrices: fuelPricesDict, averageFuelConsumption: avgFuelConsumption, totalMileage: totalMileage, defaultFuelType: defaultFuelType, mode: .defaultFuelAndStats, vehicleName: vehicleName, vehicleType: vehicleType)
                    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
                    completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
                    return
                }
                let dbURL = groupURL.appendingPathComponent("vehiclemanage.sqlite")
                
                let schema = Schema([CPCFuelPriceModel.self, Vehicle.self, FuelRecord.self])
                let config = ModelConfiguration(schema: schema, url: dbURL)
                let container = try ModelContainer(for: schema, configurations: config)
                let context = ModelContext(container)
                
                let productNames = ["無鉛汽油98", "無鉛汽油95", "無鉛汽油92", "超級/高級柴油"]
                let now = Date()
                
                for name in productNames {
                    let descriptor = FetchDescriptor<CPCFuelPriceModel>(
                        predicate: #Predicate { $0.productName == name },
                        sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
                    )
                    let results = try context.fetch(descriptor)
                    if let currentPrice = results.first(where: { $0.effectiveDate <= now }) {
                        let displayName: String
                        switch name {
                        case "無鉛汽油98": displayName = FuelType.gas98.rawValue
                        case "無鉛汽油95": displayName = FuelType.gas95.rawValue
                        case "無鉛汽油92": displayName = FuelType.gas92.rawValue
                        case "超級/高級柴油": displayName = FuelType.diesel.rawValue
                        default: displayName = name
                        }
                        fuelPricesDict[displayName] = currentPrice.price
                        
                        // 檢查未來價格
                        if let futurePrice = results.first(where: { $0.effectiveDate > now }) {
                            let difference = futurePrice.price - currentPrice.price
                            futureFuelPricesDict[displayName] = (price: futurePrice.price, difference: difference)
                        }
                    }
                }
                
                let vehicleDescriptor = FetchDescriptor<Vehicle>(
                    predicate: #Predicate { $0.isDefault == true },
                    sortBy: [SortDescriptor(\.name)]
                )
                if let defaultVehicle = try context.fetch(vehicleDescriptor).first {
                    defaultFuelType = defaultVehicle.defaultFuelType
                    vehicleName = defaultVehicle.name
                    switch defaultVehicle.vehicleType {
                    case .car:
                        vehicleType = "car.fill"
                    case .motorcycle:
                        vehicleType = "motorcycle"
                    }
                    let sortedRecords = defaultVehicle.fuelRecords.sorted(by: { $0.date < $1.date })
                    
                    if !sortedRecords.isEmpty {
                        recordCount = sortedRecords.count
                        totalCost = sortedRecords.reduce(0) { $0 + $1.cost }
                        totalFuelAmount = sortedRecords.reduce(0) { $0 + $1.fuelAmount }
                        totalMileage = sortedRecords.last?.mileage ?? 0.0
                        rangeMileage = totalMileage - (sortedRecords.first?.mileage ?? 0.0)
                        let validConsumptions = sortedRecords.filter { $0.averageFuelConsumption > 0 }.map { $0.averageFuelConsumption }
                        maxConsumption = validConsumptions.max() ?? 0.0
                        minConsumption = validConsumptions.min() ?? 0.0
                        avgFuelConsumption = rangeMileage > 0 && totalFuelAmount > 0 ? rangeMileage / totalFuelAmount : 0.0
                        costPerKm = rangeMileage > 0 ? totalCost / rangeMileage : 0.0
                    }
                }
            } catch {
                print("Widget 抓取資料失敗: \(error.localizedDescription)")
            }
            
            let mode: DisplayMode = context.family == .systemLarge ? .combined : .defaultFuelAndStats
            let entry = FuelEntry(
                date: Date(),
                fuelPrices: fuelPricesDict,
                futureFuelPrices: futureFuelPricesDict, // 傳入未來油價
                averageFuelConsumption: avgFuelConsumption,
                totalMileage: totalMileage,
                defaultFuelType: defaultFuelType,
                mode: mode,
                recordCount: recordCount,
                totalCost: totalCost,
                totalFuelAmount: totalFuelAmount,
                rangeMileage: rangeMileage,
                maxConsumption: maxConsumption,
                minConsumption: minConsumption,
                costPerKm: costPerKm,
                vehicleName: vehicleName,
                vehicleType: vehicleType
            )
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
