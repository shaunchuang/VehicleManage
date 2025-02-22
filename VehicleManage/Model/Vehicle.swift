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
    @Attribute(.unique) var name: String
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
extension Vehicle {
    func updateFuelRecordCalculations() {
        // 按日期排序紀錄
        let sortedRecords = fuelRecords.sorted(by: { $0.date < $1.date })
        
        // 遍歷所有紀錄，計算相關欄位
        for i in 0..<sortedRecords.count {
            let current = sortedRecords[i]
            if i < sortedRecords.count - 1 {
                // 有下一筆紀錄，計算 drivenDistance
                let next = sortedRecords[i + 1]
                let distance = next.mileage - current.mileage
                current.drivenDistance = distance > 0 ? distance : 0
                
                // 計算 averageFuelConsumption
                if current.fuelAmount > 0 {
                    current.averageFuelConsumption = current.drivenDistance / current.fuelAmount
                } else {
                    current.averageFuelConsumption = 0
                }
                
                // 計算 costPerKm
                if current.drivenDistance > 0 {
                    current.costPerKm = current.cost / current.drivenDistance
                } else {
                    current.costPerKm = 0
                }
            } else {
                // 最後一筆紀錄，無下一筆紀錄，將計算欄位設為 0
                current.drivenDistance = 0
                current.averageFuelConsumption = 0
                current.costPerKm = 0
            }
        }
    }
}
