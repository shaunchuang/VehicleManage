// ContentView.swift
// VehicleManage
// Created by Shaun Chuang on 2025/2/15.

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(FetchDescriptor<Vehicle>()) private var vehicles: [Vehicle]
    @State private var fuelPrices: [String: String] = [:] // 當前油價，key 使用 CPCFuelPriceModel 的 productName
    @State private var futureFuelDifferences: [String: Double] = [:] // 漲跌差額，key 使用 CPCFuelPriceModel 的 productName

    @State private var isShowingAddVehicle = false
    @State private var isShowingAddFuel = false
    @State private var isShowingDetail = false
    @State private var selectedVehicle: Vehicle?

    // 定義產品名稱映射：從 CPCFuelPriceModel 的 productName 到 FuelType 的顯示名稱
    private let fuelTypeMapping: [String: FuelType] = [
        "無鉛汽油98": .gas98,
        "無鉛汽油95": .gas95,
        "無鉛汽油92": .gas92,
        "超級/高級柴油": .diesel
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // 即時油價區塊
                    VStack(alignment: .leading) {
                        Text("即時油價")
                            .font(.title).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)

                        if !fuelPrices.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // 使用 FuelType 的顯示名稱
                                fuelPriceRow(for: .gas98)
                                fuelPriceRow(for: .gas95)
                                fuelPriceRow(for: .gas92)
                                fuelPriceRow(for: .diesel)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding([.horizontal, .top])
                        } else {
                            Text("無油價資料可顯示")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.top, 10)

                    // 車輛清單區塊
                    VStack(alignment: .leading) {
                        HStack {
                            Text("車輛清單")
                                .font(.title).bold()
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: { isShowingAddVehicle = true }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("新增車輛")
                                }
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 16)

                        if vehicles.isEmpty {
                            VStack {
                                Spacer()
                                Text("尚未新增車輛")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                Text("請點擊右上方按鈕新增車輛")
                                    .foregroundColor(.gray)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vehicles) { vehicle in
                                        VehicleCardView(
                                            vehicle: vehicle,
                                            onAddFuel: {
                                                selectedVehicle = vehicle
                                                isShowingAddFuel = true
                                            },
                                            onManage: {
                                                selectedVehicle = vehicle
                                                isShowingDetail = true
                                            }
                                        )
                                    }
                                }
                                .padding()
                            }
                            .frame(height: 200)
                        }
                    }

                    Spacer()
                }
            }
            .sheet(isPresented: $isShowingAddVehicle) {
                AddVehicleView()
            }
            .sheet(isPresented: $isShowingAddFuel) {
                if let selectedVehicle = selectedVehicle {
                    AddFuelRecordView(
                        vehicle: selectedVehicle,
                        fuelPrices: fuelPrices.mapValues { Double($0) ?? 0.0 }
                    )
                }
            }
            .navigationDestination(isPresented: $isShowingDetail) {
                if let selectedVehicle = selectedVehicle {
                    VehicleDetailView(
                        vehicle: selectedVehicle,
                        fuelPrices: fuelPrices.mapValues { Double($0) ?? 0.0 }
                    )
                }
            }
            .task {
                await fetchFuelPricesAndDifferences()
            }
        }
    }

    // MARK: - Helper Methods

    /// 為特定油品生成油價顯示行
    private func fuelPriceRow(for fuelType: FuelType) -> some View {
        let productName = fuelTypeMapping.first(where: { $0.value == fuelType })?.key ?? ""
        print("DEBUG: Rendering \(fuelType.rawValue), productName: \(productName), fuelPrices[\(productName)] = \(fuelPrices[productName] ?? "nil"), diff = \(futureFuelDifferences[productName] ?? 0)")
        
        if let diff = futureFuelDifferences[productName], diff != 0 {
            return Text("\(fuelType.rawValue)(未來): \(fuelPrices[productName] ?? "") 元/公升 (\(diffText(diff: diff)))")
                .foregroundColor(diff > 0 ? .red : .green)
                .eraseToAnyView()
        } else if let price = fuelPrices[productName] {
            return Text("\(fuelType.rawValue)：\(price) 元/公升")
                .eraseToAnyView()
        }
        return Text("") // 若無資料則返回空文字
            .eraseToAnyView()
    }

    /// 從 SwiftData 中獲取當前和未來油價，並計算漲跌差額
    private func fetchFuelPricesAndDifferences() async {
        let productNames = ["無鉛汽油98", "無鉛汽油95", "無鉛汽油92", "超級/高級柴油"]
        let currentDate = Date()
        
        print("DEBUG: 當前日期: \(currentDate)")

        do {
            for productName in productNames {
                print("DEBUG: 查詢產品: \(productName)")
                
                let descriptor = FetchDescriptor<CPCFuelPriceModel>(
                    predicate: #Predicate { $0.productName == productName },
                    sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
                )
                
                let allPrices = try modelContext.fetch(descriptor)
                for price in allPrices {
                    print("DEBUG: \(productName) - Actual ProductName: \(price.productName), EffectiveDate: \(price.effectiveDate), Price: \(price.price)")
                }
                
                print("DEBUG: \(productName) 總記錄數: \(allPrices.count)")
                if allPrices.isEmpty {
                    print("DEBUG: \(productName) 無資料")
                    continue
                }
                
                for price in allPrices {
                    print("DEBUG: \(productName) - EffectiveDate: \(price.effectiveDate), Price: \(price.price)")
                }

                if let currentPrice = allPrices.first(where: { $0.effectiveDate <= currentDate }) {
                    fuelPrices[productName] = String(format: "%.2f", currentPrice.price)
                    print("DEBUG: \(productName) 當前油價: \(currentPrice.price), EffectiveDate: \(currentPrice.effectiveDate)")
                    
                    if let futurePrice = allPrices.first(where: { $0.effectiveDate > currentDate }) {
                        let difference = futurePrice.price - currentPrice.price
                        futureFuelDifferences[productName] = difference
                        fuelPrices[productName] = String(format: "%.2f", futurePrice.price)
                        print("DEBUG: \(productName) 未來油價: \(futurePrice.price), EffectiveDate: \(futurePrice.effectiveDate), 漲跌: \(difference)")
                    } else {
                        futureFuelDifferences[productName] = 0
                        print("DEBUG: \(productName) 無未來油價")
                    }
                } else {
                    print("DEBUG: \(productName) 無當前生效油價")
                }
            }
            
            print("DEBUG: 最終 fuelPrices: \(fuelPrices)")
            print("DEBUG: 最終 futureFuelDifferences: \(futureFuelDifferences)")
        } catch {
            print("獲取油價資料失敗: \(error)")
        }
    }

    /// 顯示漲跌文字
    private func diffText(diff: Double) -> String {
        if diff > 0 {
            return "+\(String(format: "%.2f", diff))"
        } else if diff < 0 {
            return String(format: "%.2f", diff)
        } else {
            return "0"
        }
    }
}

// 輔助方法：將 View 轉為 AnyView
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

#Preview {
    ContentView()
}
