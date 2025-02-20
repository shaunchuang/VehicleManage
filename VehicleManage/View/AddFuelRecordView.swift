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
    
    @State private var fuelPrices: [String: Double] = [:]
    
    @State private var date = Date()
    @State private var mileage: String = ""
    @State private var fuelAmount: String = ""
    @State private var cost: String = ""
    @State private var fuelType: FuelType

    // 新增錯誤提示狀態變數
    @State private var showMileageError: Bool = false

    init(vehicle: Vehicle, fuelPrices: [String: Double]) {
        self.vehicle = vehicle
        _fuelType = State(initialValue: vehicle.defaultFuelType)
        self._fuelPrices = State(initialValue: fuelPrices)
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
                    HStack {
                        TextField("總里程數", text: $mileage)
                            .keyboardType(.decimalPad)
                        Text("公里")
                            .foregroundColor(.secondary)
                    }
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
                    HStack {
                        TextField("加油量", text: $fuelAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: fuelAmount) {
                                calculateFuelCost()
                            }
                        Text("公升")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        TextField("加油金額", text: $cost)
                            .keyboardType(.decimalPad)
                        Text("元")
                            .foregroundColor(.secondary)
                    }
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
                        // 取得最後一筆紀錄並驗證輸入的里程數是否大於上一筆的
                        if let lastRecord = vehicle.fuelRecords.sorted(by: { $0.date < $1.date }).last,
                           let newMileage = Double(mileage),
                           newMileage <= lastRecord.mileage {
                            showMileageError = true
                            return
                        }
                        saveRecord()
                        dismiss()
                    }
                }
            }
            .alert("里程數錯誤", isPresented: $showMileageError, actions: {
                Button("確定", role: .cancel) { }
            }, message: {
                Text("總里程數必須大於上一筆紀錄的總里程數")
            })
        }
    }

    private func saveRecord() {
        let m = Double(mileage) ?? 0
        let f = Double(fuelAmount) ?? 0
        let c = Double(cost) ?? 0

        // 取得上一筆紀錄，若無則回傳 nil
        let lastRecord = vehicle.fuelRecords.sorted(by: { $0.date < $1.date }).last

        var distance = 0.0
        var avgConsumption = 0.0
        var costPerKm = 0.0

        if let prevRecord = lastRecord {
            distance = m - prevRecord.mileage
            if distance < 0 {
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
    
    private func calculateFuelCost() {
        guard let amount = Double(fuelAmount), amount > 0 else {
            cost = ""
            return
        }
        
        if let price = fuelPrices[fuelType.rawValue] {
            let totalCost = amount * price
            cost = String(format: "%.0f", totalCost)  // 四捨五入到個位數
        } else {
            cost = ""
        }
    }
}

