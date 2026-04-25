// FuelPriceManager.swift
// VehicleManage
// Created by Shaun Chuang on 2025/2/15.

import SwiftData
import Foundation

class FuelPriceManager {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// 從 CPC API 獲取並更新油價資料
    func fetchDataFromCPCAPI() async {
        let prodIds = [1, 2, 3, 4] // CPC 油價的四種類型

        do {
            for prodId in prodIds {
                guard let url = URL(
                    string: "https://vipmbr.cpc.com.tw/cpcstn/listpricewebservice.asmx/getCPCMainProdListPrice_Historical?prodid=\(prodId)"
                ) else {
                    print("無效的 URL: prodid=\(prodId)")
                    continue
                }
                
                print("DEBUG: 開始抓取 CPC 油價資料 (prodid=\(prodId))")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // 檢查 HTTP 狀態碼
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    print("DEBUG: API 回應錯誤 (prodid=\(prodId))")
                    continue
                }
                
                print("DEBUG: 成功取得 CPC 油價資料 (prodid=\(prodId))")
                
                let parser = XMLParser(data: data)
                let delegate = FuelPriceXMLParserDelegate()
                parser.delegate = delegate
                
                if parser.parse() {
                    let models = delegate.models
                    guard !models.isEmpty else {
                        print("DEBUG: 無資料可解析 (prodid=\(prodId))")
                        continue
                    }

                    try syncFuelPrices(models)
                    print("DEBUG: 完成油價同步 (prodid=\(prodId))")
                } else {
                    print("DEBUG: XML 解析失敗 (prodid=\(prodId))")
                }
            }
            
            // 顯示最新資料與總筆數
            if let latest = try FuelPriceDataService.fetchLatestFuelPrice(context: context) {
                print("最新油價資料: \(latest.productName), \(latest.price), \(latest.effectiveDate)")
            }
            print("SwiftData 內油價資料總筆數: \(try FuelPriceDataService.countAllFuelPrices(context: context))")
        } catch {
            print("處理 CPC 油價資料時發生錯誤: \(error)")
        }
    }

    private func syncFuelPrices(_ apiModels: [CPCFuelPriceModel]) throws {
        guard let productName = apiModels.first?.productName else { return }

        let descriptor = FetchDescriptor<CPCFuelPriceModel>(
            predicate: #Predicate { $0.productName == productName },
            sortBy: [SortDescriptor(\.effectiveDate)]
        )
        let existingModels = try context.fetch(descriptor)
        let plan = FuelPriceImportPlanner.plan(
            apiSnapshots: apiModels.map {
                FuelPriceSnapshot(effectiveDate: $0.effectiveDate, price: $0.price)
            },
            existingSnapshots: existingModels.map {
                FuelPriceSnapshot(effectiveDate: $0.effectiveDate, price: $0.price)
            }
        )

        let existingByDate = Dictionary(grouping: existingModels, by: \.effectiveDate)
        var hasChanges = false

        for duplicateDate in plan.duplicateDates {
            guard let records = existingByDate[duplicateDate], let primary = records.first
            else { continue }

            if let latestSnapshot = apiModels.first(where: {
                $0.effectiveDate == duplicateDate
            }), primary.price != latestSnapshot.price {
                primary.price = latestSnapshot.price
                hasChanges = true
            }

            for duplicate in records.dropFirst() {
                context.delete(duplicate)
                hasChanges = true
            }
        }

        for snapshot in plan.updates {
            guard let record = existingByDate[snapshot.effectiveDate]?.first,
                record.price != snapshot.price
            else { continue }

            record.price = snapshot.price
            hasChanges = true
        }

        for snapshot in plan.inserts {
            context.insert(
                CPCFuelPriceModel(
                    productName: productName,
                    price: snapshot.price,
                    effectiveDate: snapshot.effectiveDate
                )
            )
            hasChanges = true
        }

        if hasChanges {
            try context.save()
        }
    }
}
