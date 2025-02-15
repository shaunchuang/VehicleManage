//
//  FuelRecord.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import Foundation
import SwiftData

@Model class FuelRecord {
    
    @Attribute(.unique)var id: UUID = UUID()
    var date: Date
    /// 假設 mileage 仍為「目前總里程」的里程表數值
    var mileage: Double
    var fuelAmount: Double
    var cost: Double
    /// 用來真正儲存油品類型的原始值 (String)
    var fuelTypeRawValue: String

    /// 將前面的原始值轉回 enum
    var fuelType: FuelType {
        get { FuelType(rawValue: fuelTypeRawValue) ?? .gas95 }
        set { fuelTypeRawValue = newValue.rawValue }
    }


    /// 這次到下次加油的行駛里程
    var drivenDistance: Double
    /// 平均油耗（公里/公升）
    var averageFuelConsumption: Double
    /// 一公里花費
    var costPerKm: Double

    init(
        date: Date,
        mileage: Double,
        fuelAmount: Double,
        cost: Double,
        fuelType: FuelType,
        drivenDistance: Double = 0,
        averageFuelConsumption: Double = 0,
        costPerKm: Double = 0
    ) {
        self.date = date
        self.mileage = mileage
        self.fuelAmount = fuelAmount
        self.cost = cost

        // 初始化時將 enum 轉成 String
        self.fuelTypeRawValue = fuelType.rawValue

        self.drivenDistance = drivenDistance
        self.averageFuelConsumption = averageFuelConsumption
        self.costPerKm = costPerKm
    }

}
