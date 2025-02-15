//
//  Vehicle.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import Foundation
import SwiftData

@Model class Vehicle {
    @Attribute(.unique)var id: UUID = UUID()
    var name: String

    /// 用來真正儲存油品類型的原始值 (String)
    var defaultFuelTypeRawValue: String

    /// 將前面的原始值轉回 enum
    var defaultFuelType: FuelType {
        get { FuelType(rawValue: defaultFuelTypeRawValue) ?? .gas95 }
        set { defaultFuelTypeRawValue = newValue.rawValue }
    }

    var fuelRecords: [FuelRecord] = []

    init(name: String, defaultFuelType: FuelType) {
        self.name = name
        // 初始化時將 enum 轉成 String
        self.defaultFuelTypeRawValue = defaultFuelType.rawValue
    }
}

