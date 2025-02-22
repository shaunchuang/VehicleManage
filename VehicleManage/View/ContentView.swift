//
//  ContentView.swift
//  VehicleManage
//  Created by Shaun Chuang on 2025/2/15.
//

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
    
    private let fuelTypeMapping: [String: FuelType] = [
        "無鉛汽油98": .gas98,
        "無鉛汽油95": .gas95,
        "無鉛汽油92": .gas92,
        "超級/高級柴油": .diesel
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 即時油價區塊
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "fuelpump.fill")
                                .foregroundStyle(.blue)
                            Text("即時油價")
                                .font(.title2.bold())
                        }
                        .padding(.horizontal)
                        
                        if !fuelPrices.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                fuelPriceRow(for: .gas98)
                                fuelPriceRow(for: .gas95)
                                fuelPriceRow(for: .gas92)
                                fuelPriceRow(for: .diesel)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                        } else {
                            Text("無油價資料可顯示")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    // 車輛清單區塊
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundStyle(.orange)
                            Text("車輛清單")
                                .font(.title2.bold())
                            Spacer()
                            Button(action: { isShowingAddVehicle = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("新增車輛")
                                }
                                .font(.subheadline)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color.blue.gradient)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                                .shadow(radius: 1)
                            }
                        }
                        .padding(.horizontal)
                        
                        if vehicles.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "car.side")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.gray.opacity(0.5))
                                Text("尚未新增車輛")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                Text("點擊右上角新增您的第一輛車")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
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
                                .padding(.horizontal)
                            }
                            .frame(height: 220)
                        }
                    }
                }
            }
            //.navigationTitle("車輛管理")
            .background(Color(.systemGroupedBackground))
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
    
    private func fuelPriceRow(for fuelType: FuelType) -> some View {
        let productName = fuelTypeMapping.first(where: { $0.value == fuelType })?.key ?? ""
        
        if let diff = futureFuelDifferences[productName], diff != 0 {
            return HStack {
                Text(fuelType.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(fuelPrices[productName] ?? "") 元/公升")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text("(\(diffText(diff: diff)))")
                    .font(.caption)
                    .foregroundStyle(diff > 0 ? .red : .green)
                    .padding(.horizontal, 6)
                    .background(diff > 0 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
            .eraseToAnyView()
        } else if let price = fuelPrices[productName] {
            return HStack {
                Text(fuelType.rawValue)
                    .font(.subheadline)
                Spacer()
                Text("\(price) 元/公升")
                    .font(.subheadline)
            }
            .eraseToAnyView()
        }
        return Text("")
            .eraseToAnyView()
    }
    
    private func fetchFuelPricesAndDifferences() async {
        let productNames = ["無鉛汽油98", "無鉛汽油95", "無鉛汽油92", "超級/高級柴油"]
        let currentDate = Date()
        
        do {
            for productName in productNames {
                let descriptor = FetchDescriptor<CPCFuelPriceModel>(
                    predicate: #Predicate { $0.productName == productName },
                    sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
                )
                
                let allPrices = try modelContext.fetch(descriptor)
                if let currentPrice = allPrices.first(where: { $0.effectiveDate <= currentDate }) {
                    fuelPrices[productName] = String(format: "%.2f", currentPrice.price)
                    if let futurePrice = allPrices.first(where: { $0.effectiveDate > currentDate }) {
                        let difference = futurePrice.price - currentPrice.price
                        futureFuelDifferences[productName] = difference
                        fuelPrices[productName] = String(format: "%.2f", futurePrice.price)
                    } else {
                        futureFuelDifferences[productName] = 0
                    }
                }
            }
        } catch {
            print("獲取油價資料失敗: \(error)")
        }
    }
    
    private func diffText(diff: Double) -> String {
        if diff > 0 {
            return "↑ \(String(format: "%.2f", diff))"
        } else if diff < 0 {
            return "↓ \(String(format: "%.2f", -diff))"
        } else {
            return "無變化"
        }
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

#Preview {
    ContentView()
}
