//
//  VehicleManageApp.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import SwiftUI
import SwiftData

@main
struct VehicleManageApp: App {
    let modelContainer: ModelContainer
    
    init() {
            do {
                // 初始化 SwiftData 的模型容器
                modelContainer = try ModelContainer(for: CPCFuelPriceModel.self, Vehicle.self, FuelRecord.self)
            } catch {
                fatalError("無法建立模型容器：\(error)")
            }
        }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, modelContainer.mainContext)
                .task { // 在這裡執行異步任務
                                    await fetchDataFromCPCAPI()
                                }
        }
    }
    
    func fetchDataFromCPCAPI() async {
        guard let url = URL(string: "https://vipmbr.cpc.com.tw/cpcstn/listpricewebservice.asmx/getCPCMainProdListPrice_Historical?prodid=1") else {
            print("無效的 URL")
            return
        }
        
        do {
            // 發送網路請求並取得資料
            print("DEBUG: 開始抓取 CPC 油價資料")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("DEBUG: 成功取得 CPC 油價資料")
            print("DEBUG: data", String(data: data, encoding: .utf8) ?? "無法解碼資料")
            
            // 解析 XML 並儲存到 SwiftData
            let parser = XMLParser(data: data)
            let delegate = FuelPriceXMLParserDelegate()
            parser.delegate = delegate
            if parser.parse() {
                let models = delegate.models
                let context = modelContainer.mainContext
                
                // 將解析的模型插入 SwiftData
                for model in models {
                    context.insert(model)
                }
                
                // 儲存變更
                do {
                    try context.save()
                    print("DEBUG: 成功儲存 \(models.count) 筆資料到 SwiftData")
                } catch {
                    print("儲存到 SwiftData 失敗: \(error)")
                }
            } else {
                print("XML 解析失敗")
            }
        } catch {
            print("獲取 CPC 油價失敗: \(error)")
        }
    }
}


