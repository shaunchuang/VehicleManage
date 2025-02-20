//
//  Vehicle.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import Foundation
import SwiftData

enum VehicleType: String, CaseIterable, Identifiable {
    case car = "汽車"
    case motorcycle = "機車"

    var id: String {
        self.rawValue
    }
}


@Model class Vehicle {
    @Attribute(.unique)var id: UUID = UUID()
    @Attribute(.unique)var name: String
    var vehicleTypeRawValue: String  // 儲存車輛類型的原始值 (String)

    /// 轉換 enum
    var vehicleType: VehicleType {
        get { VehicleType(rawValue: vehicleTypeRawValue) ?? .car }
        set { vehicleTypeRawValue = newValue.rawValue }
    }

    var defaultFuelTypeRawValue: String

    var defaultFuelType: FuelType {
        get { FuelType(rawValue: defaultFuelTypeRawValue) ?? .gas95 }
        set { defaultFuelTypeRawValue = newValue.rawValue }
    }

    var fuelRecords: [FuelRecord] = []

    init(name: String, vehicleType: VehicleType, defaultFuelType: FuelType) {
        self.name = name
        self.vehicleTypeRawValue = vehicleType.rawValue
        self.defaultFuelTypeRawValue = defaultFuelType.rawValue
    }
}

