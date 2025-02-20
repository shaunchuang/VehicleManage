//
//  EditFuelRecordView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/16.
//

import SwiftUI

struct EditFuelRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var record: FuelRecord
    
    @State private var date: Date
    @State private var mileage: String
    @State private var fuelAmount: String
    @State private var cost: String
    @State private var fuelType: FuelType

    // 使用 init 將目前紀錄值帶入 state
    init(record: FuelRecord) {
        self.record = record
        _date = State(initialValue: record.date)
        _mileage = State(initialValue: String(format: "%.1f", record.mileage))
        _fuelAmount = State(initialValue: String(format: "%.1f", record.fuelAmount))
        _cost = State(initialValue: String(format: "%.0f", record.cost))
        _fuelType = State(initialValue: record.fuelType)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本資訊")) {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                    TextField("里程數（公里）", text: $mileage)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("加油資訊")) {
                    Picker("油品種類", selection: $fuelType) {
                        ForEach(FuelType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("加油量（公升）", text: $fuelAmount)
                        .keyboardType(.decimalPad)
                    TextField("加油金額", text: $cost)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("編輯油耗紀錄")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // 儲存修改：更新 record 的屬性
    private func saveChanges() {
        let m = Double(mileage) ?? record.mileage
        let f = Double(fuelAmount) ?? record.fuelAmount
        let c = Double(cost) ?? record.cost
        
        record.date = date
        record.mileage = m
        record.fuelAmount = f
        record.cost = c
        record.fuelType = fuelType
        
        // 如有需要，也可在此處重新計算 drivenDistance、averageFuelConsumption、costPerKm
    }
}
