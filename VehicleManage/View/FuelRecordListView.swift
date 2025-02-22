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
                        .font(.headline)
                    Spacer()
                    Text("共 \(vehicle.fuelRecords.count) 筆紀錄")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            
            List {
                ForEach(vehicle.fuelRecords.sorted(by: { $0.date > $1.date })) { record in
                    NavigationLink(destination: EditFuelRecordView(record: record, vehicle: vehicle)) {
                        FuelRecordRow(record: record)
                    }
                }
                .onDelete(perform: deleteRecord)
            }
            .listStyle(.plain)
            
            // 查看圖表按鈕 (縮小)
            NavigationLink(destination: FuelConsumptionChartView(vehicle: vehicle)) {
                Text("查看油耗圖表")
                    .font(.subheadline)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // 新增油耗紀錄按鈕 (縮小)
            Button {
                isShowingAddFuel = true
            } label: {
                Text("新增油耗紀錄")
                    .font(.subheadline)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .padding(.top, 8)
        }
        .navigationTitle("油耗紀錄")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("+ 新增油耗紀錄") {
                    isShowingAddFuel = true
                }
            }
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
            vehicle.updateFuelRecordCalculations()
        }
    }
}

// 新增 FuelRecordRow 來美化單筆紀錄呈現
struct FuelRecordRow: View {
    let record: FuelRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日期與油品
            HStack {
                Text(record.date, format: .dateTime.year().month().day())
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(record.fuelType.rawValue)
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // 主要數據
            HStack(spacing: 16) {
                // 里程與油耗
                VStack(alignment: .leading, spacing: 4) {
                    RecordItem(label: "里程", value: String(format: "%.1f km", record.mileage))
                    RecordItem(label: "油耗", value: String(format: "%.2f km/L", record.averageFuelConsumption))
                }
                
                // 加油量與金額
                VStack(alignment: .leading, spacing: 4) {
                    RecordItem(label: "加油量", value: String(format: "%.1f L", record.fuelAmount))
                    RecordItem(label: "金額", value: String(format: "$%.0f", record.cost))
                }
            }
            
            // 行駛距離與每公里花費
            HStack {
                RecordItem(label: "行駛", value: String(format: "%.1f km", record.drivenDistance))
                Spacer()
                RecordItem(label: "每公里", value: String(format: "$%.2f", record.costPerKm))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// 輔助視圖：單一數據項目
struct RecordItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }
}
