
//
//  ContentView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//
// ContentView.swift

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(FetchDescriptor<Vehicle>()) private var vehicles: [Vehicle]
    @State private var fuelPrices: [String: String] = [:]
    @State private var futureFuelDifferences: [String: Double] = [:]

    @State private var isShowingAddVehicle = false
    @State private var isShowingAddFuel = false
    @State private var isShowingDetail = false
    @State private var selectedVehicle: Vehicle?

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
                                if let diff98 = futureFuelDifferences["98無鉛"], diff98 != 0 {
                                    Text("98無鉛(未來): \(fuelPrices["98無鉛"] ?? "") 元/公升 (\(diffText(diff: diff98)))")
                                        .foregroundColor(diff98 > 0 ? .red : .green)
                                } else if let price98 = fuelPrices["98無鉛"] {
                                    Text("98無鉛：\(price98) 元/公升")
                                }
                                if let diff95 = futureFuelDifferences["95無鉛"], diff95 != 0 {
                                    Text("95無鉛(未來): \(fuelPrices["95無鉛"] ?? "") 元/公升 (\(diffText(diff: diff95)))")
                                        .foregroundColor(diff95 > 0 ? .red : .green)
                                } else if let price95 = fuelPrices["95無鉛"] {
                                    Text("95無鉛：\(price95) 元/公升")
                                }
                                if let diff92 = futureFuelDifferences["92無鉛"], diff92 != 0 {
                                    Text("92無鉛(未來): \(fuelPrices["92無鉛"] ?? "") 元/公升 (\(diffText(diff: diff92)))")
                                        .foregroundColor(diff92 > 0 ? .red : .green)
                                } else if let price92 = fuelPrices["92無鉛"] {
                                    Text("92無鉛：\(price92) 元/公升")
                                }
                                if let diffDiesel = futureFuelDifferences["柴油"], diffDiesel != 0 {
                                    Text("柴油(未來): \(fuelPrices["柴油"] ?? "") 元/公升 (\(diffText(diff: diffDiesel)))")
                                        .foregroundColor(diffDiesel > 0 ? .red : .green)
                                } else if let priceDiesel = fuelPrices["柴油"] {
                                    Text("柴油：\(priceDiesel) 元/公升")
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding([.horizontal, .top])
                        }
                    }
                    .padding(.top, 10)
                    
                    // 車輛清單區塊
                    VStack(alignment: .leading) {
                        HStack {
                            Text("車輛清單")
                                .font(.title).bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                isShowingAddVehicle = true
                            }) {
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
                                            // 點擊「油耗」按鈕，設定對應車輛並顯示新增油耗紀錄的 sheet
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
            // 彈出視窗：新增車輛
            .sheet(isPresented: $isShowingAddVehicle) {
                AddVehicleView()
            }
            
            .sheet(isPresented: $isShowingAddFuel) {
                if let selectedVehicle = selectedVehicle {
                    AddFuelRecordView(vehicle: selectedVehicle, fuelPrices: fuelPrices.mapValues { Double($0) ?? 0.0 })
                }
            }
            
            // 進入車輛管理頁 (Navigation)
            .navigationDestination(isPresented: $isShowingDetail) {
                if let selectedVehicle = selectedVehicle {
                    VehicleDetailView(vehicle: selectedVehicle, fuelPrices: fuelPrices.mapValues { Double($0) ?? 0.0 })
                }
            }
            .task {
                let fuelPriceManager = FuelPriceManager(modelContext: modelContext)
                // 先從 API 取得資料並更新 SwiftData
                await fuelPriceManager.fetchAndUpdateFuelPrices()
                // 接著更新 UI 的油價顯示
                fuelPriceManager.updateFuelPriceDisplay()
                fuelPrices = fuelPriceManager.fuelPrices
                futureFuelDifferences = fuelPriceManager.futureFuelDifferences
            }
        }
    }

    
    // ★★★ 輔助方法：將 API 回傳的日期字串轉 Date
        private func dateFromString(_ dateString: String) -> Date? {
            // 請依據真正的 API 日期格式自定 formatter
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateString)
        }

        // ★★★ 顯示漲或跌
        private func diffText(diff: Double) -> String {
            if diff > 0 {
                return "+\(String(format: "%.2f", diff))"
            } else if diff < 0 {
                return "\(String(format: "%.2f", diff))"
            } else {
                return "0"
            }
        }
}
