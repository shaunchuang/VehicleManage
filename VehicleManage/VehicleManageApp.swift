// VehicleManageApp.swift
// VehicleManage
// Created by Shaun Chuang on 2025/2/15.

import SwiftData
import SwiftUI

@main
struct VehicleManageApp: App {
    let modelContainer: ModelContainer
    @AppStorage("lastFetchDate") private var lastFetchDate: Double = 0 // 儲存上次抓取時間（時間戳）

    init() {
        do {
            modelContainer = try ModelContainer(for: CPCFuelPriceModel.self, Vehicle.self, FuelRecord.self)
        } catch {
            fatalError("無法建立模型容器：\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(modelContainer: modelContainer, lastFetchDate: $lastFetchDate)
        }
    }
}
