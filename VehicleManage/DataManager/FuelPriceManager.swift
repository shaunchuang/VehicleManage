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
            // 取得 SwiftData 中最新的油價資料
            let latestStoredPrice = try FuelPriceDataService.fetchLatestFuelPrice(context: context)
            
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
                    
                    // 檢查 API 的最新油價是否需要更新
                    if let latestAPIPrice = models.max(by: { $0.effectiveDate < $1.effectiveDate }),
                       let latestStored = latestStoredPrice,
                       latestAPIPrice.effectiveDate <= latestStored.effectiveDate {
                        print("DEBUG: API 最新油價與 SwiftData 相同，無需更新 (prodid=\(prodId))")
                        continue
                    }
                    
                    // 插入新資料
                    for model in models {
                        context.insert(model)
                    }
                    
                    try context.save()
                    print("DEBUG: 成功儲存 \(models.count) 筆資料到 SwiftData (prodid=\(prodId))")
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
}
