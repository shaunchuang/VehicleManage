import Foundation
import SwiftData
import WidgetKit

enum DisplayMode {
    case allFuelPrices
    case defaultFuelAndStats
    case combined
}

struct FuelEntry: TimelineEntry {
    let date: Date
    let fuelPrices: [String: Double]
    let averageFuelConsumption: Double
    let totalMileage: Double
    let defaultFuelType: FuelType
    let mode: DisplayMode
    let recordCount: Int
    let totalCost: Double
    let totalFuelAmount: Double
    let rangeMileage: Double
    let maxConsumption: Double
    let minConsumption: Double
    let costPerKm: Double
    let vehicleName: String // 新增車輛名稱
    let vehicleType: String // 新增車輛種類
    
    init(date: Date, fuelPrices: [String: Double], averageFuelConsumption: Double, totalMileage: Double, defaultFuelType: FuelType, mode: DisplayMode, recordCount: Int = 0, totalCost: Double = 0.0, totalFuelAmount: Double = 0.0, rangeMileage: Double = 0.0, maxConsumption: Double = 0.0, minConsumption: Double = 0.0, costPerKm: Double = 0.0, vehicleName: String = "未知車輛", vehicleType: String = "car.fill") {
        self.date = date
        self.fuelPrices = fuelPrices
        self.averageFuelConsumption = averageFuelConsumption
        self.totalMileage = totalMileage
        self.defaultFuelType = defaultFuelType
        self.mode = mode
        self.recordCount = recordCount
        self.totalCost = totalCost
        self.totalFuelAmount = totalFuelAmount
        self.rangeMileage = rangeMileage
        self.maxConsumption = maxConsumption
        self.minConsumption = minConsumption
        self.costPerKm = costPerKm
        self.vehicleName = vehicleName
        self.vehicleType = vehicleType
    }
}
