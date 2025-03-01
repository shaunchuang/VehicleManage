import SwiftData
import SwiftUI

@main
struct VehicleManageApp: App {
    let modelContainer: ModelContainer
    @AppStorage("lastFetchDate", store: UserDefaults(suiteName: "group.ShaunChuang.VehicleManage")) private var lastFetchDate: Double = 0

    init() {
        do {
            let schema = Schema([CPCFuelPriceModel.self, Vehicle.self, FuelRecord.self])
            guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ShaunChuang.VehicleManage") else {
                print("無法獲取 App Group 路徑，使用預設配置")
                // 回退到預設配置，避免崩潰
                modelContainer = try ModelContainer(for: schema)
                return
            }
            let dbURL = groupURL.appendingPathComponent("vehiclemanage.sqlite")
            let config = ModelConfiguration(schema: schema, url: dbURL)
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("無法建立模型容器：\(error)") // 保留這一行處理其他錯誤
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(modelContainer: modelContainer, lastFetchDate: $lastFetchDate)
        }
    }
}
