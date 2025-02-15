//
//  VehicleManageApp.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import SwiftUI
import SwiftData

@main
struct VehicleManageApp: App {
    // 這裡建立並初始化 ModelContainer
    var sharedModelContainer: ModelContainer = {
        // 如果有多個模型，全部列在這裡
        let schema = Schema([
            Vehicle.self,
            FuelRecord.self
        ])

        do {
            // 也可以加上自訂 ModelConfiguration，或者只要預設即可
            let container = try ModelContainer(for: schema)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 將 ModelContainer 綁到整個視圖階層
                .modelContainer(sharedModelContainer)
        }
    }
}

