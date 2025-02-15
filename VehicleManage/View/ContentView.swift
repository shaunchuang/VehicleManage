
//
//  ContentView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    @State private var fuelPrices: [String: String] = [:]
    
    @State private var selectedVehicleID: UUID?
    @State private var isShowingAddVehicle = false
    @State private var isShowingDetail = false
    @State private var isShowingAddFuel = false

    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - 即時油價區塊
                VStack(alignment: .leading) {
                    Text("即時油價")
                        .font(.title).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)// 讓標題靠左對齊

                    if !fuelPrices.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            if let price98 = fuelPrices["98無鉛"] {
                                HStack {
                                    Text("98無鉛：")
                                    Spacer()
                                    Text("\(price98) 元/公升")
                                }
                            }

                            if let price95 = fuelPrices["95無鉛"] {
                                HStack {
                                    Text("95無鉛：")
                                    Spacer()
                                    Text("\(price95) 元/公升")
                                }
                            }
                            if let price92 = fuelPrices["92無鉛"] {
                                HStack {
                                    Text("92無鉛：")
                                    Spacer()
                                    Text("\(price92) 元/公升")
                                }
                            }
                            if let priceDiesel = fuelPrices["柴油"] {
                                HStack {
                                    Text("柴油：")
                                    Spacer()
                                    Text("\(priceDiesel) 元/公升")
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding([.horizontal, .top])
                    }
                }
                .padding(.top, 10)

                // MARK: - 車輛清單區塊
                VStack(alignment: .leading) {
                    Text("車輛清單")
                        .font(.title).bold()
                        .frame(maxWidth: .infinity, alignment: .leading) // 讓標題靠左對齊
                        .padding(.top, 10)
                        .padding(.horizontal, 16)
                    
                    if vehicles.isEmpty {
                        Spacer()
                        Text("尚未新增車輛")
                            .foregroundColor(.gray)
                        Text("請點擊右上方按鈕新增車輛")
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(vehicles) { vehicle in
                                    VehicleCardView(
                                        vehicle: vehicle,
                                        isSelected: (selectedVehicleID == vehicle.id),
                                        onSelect: {
                                            selectedVehicleID = vehicle.id
                                        },
                                        onDelete: {
                                            deleteVehicle(vehicle)
                                        },
                                        onAddFuel: {
                                            selectedVehicleID = vehicle.id
                                            isShowingAddFuel = true
                                        },
                                        onManage: {
                                            selectedVehicleID = vehicle.id
                                            isShowingDetail = true
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                        .frame(height: 240)
                    }
                }

                Spacer()
            }
            // MARK: - 工具列
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddVehicle = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("新增車輛")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingAddVehicle) {
                AddVehicleView()
            }
            .navigationDestination(isPresented: $isShowingDetail) {
                if let selectedVehicle = vehicles.first(where: { $0.id == selectedVehicleID }) {
                    VehicleDetailView(vehicle: selectedVehicle)
                }
            }
            .sheet(isPresented: $isShowingAddFuel) {
                if let selectedVehicle = vehicles.first(where: { $0.id == selectedVehicleID }) {
                    AddFuelRecordView(vehicle: selectedVehicle)
                }
            }
            .task {
                await fetchFuelPrice()
            }
        }
    }

    // MARK: - 取得油價的函式
    private func fetchFuelPrice() async {
        guard let url = URL(string: "https://vipmbr.cpc.com.tw/openData/MainProdListPrice") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API 回應 JSON: \(jsonString)")
            }
            
            let cpcData = try JSONDecoder().decode([CPCFuelPrice].self, from: data)

            var tempPrices: [String: String] = [:]
            for item in cpcData {
                if item.productName.contains("92") {
                    tempPrices["92無鉛"] = "\(item.price)"
                } else if item.productName.contains("95") {
                    tempPrices["95無鉛"] = "\(item.price)"
                } else if item.productName.contains("98") {
                    tempPrices["98無鉛"] = "\(item.price)"
                } else if item.productName.contains("超級柴油") {
                    tempPrices["柴油"] = "\(item.price)"
                }
            }

            DispatchQueue.main.async {
                self.fuelPrices = tempPrices
            }

        } catch {
            print("抓取或解析油價資訊失敗: \(error)")
        }
    }

    private func deleteVehicle(_ vehicle: Vehicle) {
        withAnimation {
            modelContext.delete(vehicle)
        }
    }
}
