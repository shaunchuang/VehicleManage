//
//  FuelRecordListView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/16.
//

import SwiftUI

struct FuelRecordListView: View {
    @Bindable var vehicle: Vehicle
    let fuelPrices: [String: Double]
    
    @State private var isShowingAddFuel = false
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("車輛：\(vehicle.name)")
                    Spacer()
                    Text("共 \(vehicle.fuelRecords.count) 筆紀錄")
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            
            List {
                ForEach(vehicle.fuelRecords.sorted(by: { $0.date > $1.date })) { record in
                    NavigationLink(destination: EditFuelRecordView(record: record, vehicle: vehicle)) {
                        VStack(alignment: .leading) {
                            Text("日期: \(record.date, format: .dateTime.year().month().day())")
                            Text("油品: \(record.fuelType.rawValue)")
                            Text(String(format: "里程數: %.1f 公里", record.mileage))
                            Text(String(format: "加油量: %.1f 公升", record.fuelAmount))
                            Text(String(format: "金額: $%.0f", record.cost))
                            Text(String(format: "行駛里程: %.1f 公里", record.drivenDistance))
                            Text(String(format: "平均油耗: %.2f 公里/公升", record.averageFuelConsumption))
                            Text(String(format: "每公里花費: $%.2f", record.costPerKm))
                        }
                    }
                }
                .onDelete(perform: deleteRecord)
            }
            .navigationTitle("油耗紀錄")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("+ 新增油耗紀錄") {
                        isShowingAddFuel = true
                    }
                }
            }
            
            NavigationLink(destination: FuelConsumptionChartView(vehicle: vehicle)) {
                Text("查看油耗圖表")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .sheet(isPresented: $isShowingAddFuel) {
            AddFuelRecordView(vehicle: vehicle, fuelPrices: fuelPrices)
        }
    }
    
    
    private func deleteRecord(offsets: IndexSet) {
        withAnimation {
            let sortedRecords = vehicle.fuelRecords.sorted(by: { $0.date < $1.date })
            for index in offsets {
                if let originalIndex = vehicle.fuelRecords.firstIndex(where: { $0.id == sortedRecords[index].id }) {
                    vehicle.fuelRecords.remove(at: originalIndex)
                }
            }
            // 刪除後更新所有紀錄的計算欄位
            vehicle.updateFuelRecordCalculations()
        }
    }
}
