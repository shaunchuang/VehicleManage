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

struct FuelRecordRow: View {
    let record: FuelRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 日期與油品標籤
            HStack {
                Text(record.date, format: Date.FormatStyle()
                    .locale(Locale(identifier: "zh-Hant-TW"))
                    .year().month().day().weekday(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(record.fuelType.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // 主要數據區塊
            HStack(spacing: 20) {
                // 左側：里程與加油量
                VStack(alignment: .leading, spacing: 8) {
                    RecordItem(label: "加油量", value: String(format: "%.1f L", record.fuelAmount), icon: "fuelpump.fill", color: .blue)
                    RecordItem(label: "里程", value: String(format: "%.1f km", record.mileage), icon: "speedometer", color: .green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右側：金額與油耗
                VStack(alignment: .leading, spacing: 8) {
                    RecordItem(label: "金額", value: String(format: "$%.0f", record.cost), icon: "dollarsign.circle", color: .orange)
                    RecordItem(label: "油耗", value: String(format: "%.2f km/L", record.averageFuelConsumption), icon: "gauge", color: .purple)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 分隔線
            Divider()
                .background(Color.gray.opacity(0.2))
            
            // 行駛距離與每公里花費
            HStack {
                RecordItem(label: "行駛", value: String(format: "%.1f km", record.drivenDistance), icon: "road.lanes", color: .gray)
                Spacer()
                RecordItem(label: "每公里", value: String(format: "$%.2f", record.costPerKm), icon: "centsign.circle", color: .gray)
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}

// 輔助視圖：單個數據項
struct RecordItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    init(label: String, value: String, icon: String = "", color: Color = .primary) {
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}
