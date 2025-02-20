//
//  FuelPriceManager.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/18.
//

import SwiftData
import Foundation
/*
class FuelPriceManager: ObservableObject {
    let modelContext: ModelContext

    @Published var fuelPrices: [String: String] = [:]
    @Published var futureFuelDifferences: [String: Double] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 更新即時油價與未來油價變動
    func fetchAndUpdateFuelPrices() async {
        let fuelPriceService = FuelPriceService()
        
        // 針對每個油品類型進行抓取
        for fuel in FuelType.allCases {
            // 根據你的 API 規範，這裡需要對應每個油品的產品代碼
            let fuelId: String
            switch fuel {
            case .gas92:
                fuelId = "gas92"   // 請依實際需求調整
            case .gas95:
                fuelId = "gas95"
            case .gas98:
                fuelId = "gas98"
            case .diesel:
                fuelId = "diesel"
            }
            
            print("DEBUG: 開始抓取 \(fuel.rawValue) 的油價資料，fuelId: \(fuelId)")
            let fetchedPrices = await fuelPriceService.fetchPrice(for: fuelId, fuelName: fuel.rawValue)
            print("DEBUG: \(fuel.rawValue) 抓取到 \(fetchedPrices.count) 筆記錄")
            
            // 逐筆檢查是否已存在
            for (productName, price, effectiveDate) in fetchedPrices {
                let predicate = Predicate<CPCFuelPriceModel> { record in
                    record.productName == productName && record.effectiveDate == effectiveDate
                }
                let descriptor = FetchDescriptor<CPCFuelPriceModel>(predicate: predicate)
                let existingRecords: [CPCFuelPriceModel] = (try? modelContext.fetch(descriptor)) ?? []
                
                if existingRecords.isEmpty {
                    let newRecord = CPCFuelPriceModel(productName: productName, price: price, effectiveDate: effectiveDate)
                    saveToDatabase(newRecord)
                    print("DEBUG: 新增 \(productName) 的油價紀錄，生效日期：\(effectiveDate)，價格：\(price)")
                } else {
                    print("DEBUG: \(productName) 生效日期 \(effectiveDate) 的紀錄已存在")
                }
            }

        }
    }

    /// 更新即時油價顯示 (此方法仍用來取出 SwiftData 中的資料更新 UI)
    func updateFuelPriceDisplay() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        
        let descriptor = FetchDescriptor<CPCFuelPriceModel>(
            sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
        )
        let fetchedData = (try? modelContext.fetch(descriptor)) ?? []
        print("DEBUG: SwiftData 中總共有 \(fetchedData.count) 筆油價紀錄")
        
        for fuel in FuelType.allCases {
            let recordsForFuel = fetchedData.filter { $0.productName == fuel.rawValue }
            let latestPrice = recordsForFuel.first?.price ?? 0.0
            print("DEBUG: 油品 \(fuel.rawValue) 找到 \(recordsForFuel.count) 筆記錄，最新價格：\(latestPrice)")
            
            let futurePrices = recordsForFuel.filter { record in
                guard let date = dateFormatter.date(from: record.effectiveDate) else { return false }
                return date > today
            }
            .sorted { $0.effectiveDate < $1.effectiveDate }
            
            if let futurePrice = futurePrices.first {
                let difference = futurePrice.price - latestPrice
                futureFuelDifferences[fuel.rawValue] = difference
                fuelPrices[fuel.rawValue] = String(format: "%.2f", futurePrice.price)
            } else {
                fuelPrices[fuel.rawValue] = String(format: "%.2f", latestPrice)
            }
        }
    }

    /// 儲存油價記錄到 SwiftData
    func saveToDatabase(_ fuelPrice: CPCFuelPriceModel) {
        modelContext.insert(fuelPrice)
        print("DEBUG: 儲存油價記錄：\(fuelPrice.productName) - \(fuelPrice.price) (\(fuelPrice.effectiveDate))")
    }

}
*/
