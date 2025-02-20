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
    let modelContainer = try! ModelContainer(for: CPCFuelPriceModel.self, Vehicle.self, FuelRecord.self)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, modelContainer.mainContext)
        }
    }
}

