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
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var vehicleTypeRawValue: String
    var vehicleType: VehicleType {
        get { VehicleType(rawValue: vehicleTypeRawValue) ?? .car }
        set { vehicleTypeRawValue = newValue.rawValue }
    }
    var defaultFuelTypeRawValue: String
    var defaultFuelType: FuelType {
        get { FuelType(rawValue: defaultFuelTypeRawValue) ?? .gas95 }
        set { defaultFuelTypeRawValue = newValue.rawValue }
    }
    @Relationship(deleteRule: .cascade, inverse: \FuelRecord.vehicle)
    var fuelRecords: [FuelRecord] = []
    var isDefault: Bool

    init(name: String, vehicleType: VehicleType, defaultFuelType: FuelType, isDefault: Bool = false) {
        self.name = name
        self.vehicleTypeRawValue = vehicleType.rawValue
        self.defaultFuelTypeRawValue = defaultFuelType.rawValue
        self.isDefault = isDefault
    }
}

extension Vehicle {
    func updateFuelRecordCalculations() {
        // 按日期排序紀錄（由舊到新）
        let sortedRecords = fuelRecords.sorted(by: { $0.date < $1.date })

        for i in 0..<sortedRecords.count {
            let current = sortedRecords[i]
            if i < sortedRecords.count - 1 {
                let next = sortedRecords[i + 1]
                let distance = FuelCalculator.drivenDistance(from: current.mileage, to: next.mileage)
                current.drivenDistance = distance
                current.averageFuelConsumption = FuelCalculator.fuelEconomy(distance: distance, fuelAmount: current.fuelAmount)
                current.costPerKm = FuelCalculator.costPerKm(cost: current.cost, distance: distance)
            } else {
                // 最後一筆紀錄，無法計算至下一次加油的距離
                current.drivenDistance = 0
                current.averageFuelConsumption = 0
                current.costPerKm = 0
            }
        }
    }
}
