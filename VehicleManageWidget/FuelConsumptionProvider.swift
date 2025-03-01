import WidgetKit
import SwiftData

struct FuelConsumptionProvider: TimelineProvider {
    func placeholder(in context: Context) -> FuelEntry {
        FuelEntry(
            date: Date(),
            fuelPrices: ["98無鉛": 34.0, "95無鉛": 32.0, "92無鉛": 30.5, "柴油": 29.5], // 修改為 "柴油"
            averageFuelConsumption: 15.2,
            totalMileage: 12345.6,
            defaultFuelType: .gas95,
            mode: .allFuelPrices
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FuelEntry) -> Void) {
        let entry = FuelEntry(
            date: Date(),
            fuelPrices: ["98無鉛": 34.0, "95無鉛": 32.0, "92無鉛": 30.5, "柴油": 29.5], // 修改為 "柴油"
            averageFuelConsumption: 15.2,
            totalMileage: 12345.6,
            defaultFuelType: .gas95,
            mode: .allFuelPrices
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FuelEntry>) -> Void) {
        Task {
            var fuelPricesDict: [String: Double] = [:]
            var defaultFuelType: FuelType = .gas95
            
            do {
                guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ShaunChuang.VehicleManage") else {
                    print("無法獲取 App Group 路徑")
                    let entry = FuelEntry(date: Date(), fuelPrices: fuelPricesDict, averageFuelConsumption: 0.0, totalMileage: 0.0, defaultFuelType: defaultFuelType, mode: .allFuelPrices)
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
                        case "超級/高級柴油": displayName = FuelType.diesel.rawValue // 這裡已經是 "柴油"
                        default: displayName = name
                        }
                        fuelPricesDict[displayName] = currentPrice.price
                    }
                }
                
                let vehicleDescriptor = FetchDescriptor<Vehicle>(
                    predicate: #Predicate { $0.isDefault == true },
                    sortBy: [SortDescriptor(\.name)]
                )
                if let defaultVehicle = try context.fetch(vehicleDescriptor).first {
                    defaultFuelType = defaultVehicle.defaultFuelType
                }
            } catch {
                print("Widget 抓取資料失敗: \(error.localizedDescription)")
            }
            
            let entry = FuelEntry(
                date: Date(),
                fuelPrices: fuelPricesDict,
                averageFuelConsumption: 0.0,
                totalMileage: 0.0,
                defaultFuelType: defaultFuelType,
                mode: .allFuelPrices
            )
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
