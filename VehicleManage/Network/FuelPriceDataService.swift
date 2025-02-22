// FuelPriceDataService.swift
// VehicleManage
// Created by Shaun Chuang on 2025/2/15.

import SwiftData
import Foundation

enum FuelPriceDataService {
    /// 獲取最新的油價資料
    /// - Parameter context: SwiftData 的模型上下文
    /// - Returns: 最新的 CPCFuelPriceModel，若無資料則返回 nil
    /// - Throws: 若從 SwiftData 獲取資料失敗，則拋出錯誤
    static func fetchLatestFuelPrice(context: ModelContext) throws -> CPCFuelPriceModel? {
        var descriptor = FetchDescriptor<CPCFuelPriceModel>(
            predicate: nil, // 可選：若需要過濾特定條件，可在此添加
            sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1 // 在初始化後設置 fetchLimit
        
        let results = try context.fetch(descriptor)
        return results.first
    }
    
    /// 計算所有油價資料的總數
    static func countAllFuelPrices(context: ModelContext) throws -> Int {
        let fetchDescriptor = FetchDescriptor<CPCFuelPriceModel>()
        return try context.fetch(fetchDescriptor).count
    }
}
