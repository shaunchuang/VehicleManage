//
//  AddFuelRecordView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import SwiftUI

struct AddFuelRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vehicle: Vehicle

    @State private var date = Date()
    @State private var mileage: String = ""
    @State private var fuelAmount: String = ""
    @State private var cost: String = ""
    @State private var fuelType: FuelType

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _fuelType = State(initialValue: vehicle.defaultFuelType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本資訊")) {
                    DatePicker(
                        "日期",
                        selection: $date,
                        displayedComponents: .date
                    )
                    TextField("里程數（公里）", text: $mileage)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("加油資訊")) {
                    Picker(
                        "油品種類",
                        selection: $fuelType
                    ) {
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
            .navigationTitle("新增油耗紀錄")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveRecord()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveRecord() {
        let m = Double(mileage) ?? 0
        let f = Double(fuelAmount) ?? 0
        let c = Double(cost) ?? 0

        // 取得上一筆紀錄，若無則回傳 nil
        let lastRecord = vehicle.fuelRecords
            .sorted(by: { $0.date < $1.date })
            .last

        var distance = 0.0
        var avgConsumption = 0.0
        var costPerKm = 0.0

        if let prevRecord = lastRecord {
            distance = m - prevRecord.mileage
            if distance < 0 {
                // 如果里程數有誤，需額外檢查處理
                distance = 0
            }
            if f > 0 {
                avgConsumption = distance / f
            }
            if distance > 0 {
                costPerKm = c / distance
            }
        }

        let newRecord = FuelRecord(
            date: date,
            mileage: m,
            fuelAmount: f,
            cost: c,
            fuelType: fuelType,
            drivenDistance: distance,
            averageFuelConsumption: avgConsumption,
            costPerKm: costPerKm
        )

        vehicle.fuelRecords.append(newRecord)
    }
}
