//
//  FuelRecord.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import Foundation
import SwiftData

@Model class FuelRecord {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var mileage: Double
    var fuelAmount: Double
    var cost: Double
    var fuelTypeRawValue: String
    var fuelType: FuelType {
        get { FuelType(rawValue: fuelTypeRawValue) ?? .gas95 }
        set { fuelTypeRawValue = newValue.rawValue }
    }
    var drivenDistance: Double
    var averageFuelConsumption: Double
    var costPerKm: Double
    var vehicle: Vehicle?  // 移除 @Relationship

    init(date: Date, mileage: Double, fuelAmount: Double, cost: Double, fuelType: FuelType, drivenDistance: Double = 0, averageFuelConsumption: Double = 0, costPerKm: Double = 0, vehicle: Vehicle? = nil) {
        self.date = date
        self.mileage = mileage
        self.fuelAmount = fuelAmount
        self.cost = cost
        self.fuelTypeRawValue = fuelType.rawValue
        self.drivenDistance = drivenDistance
        self.averageFuelConsumption = averageFuelConsumption
        self.costPerKm = costPerKm
        self.vehicle = vehicle
    }
}
