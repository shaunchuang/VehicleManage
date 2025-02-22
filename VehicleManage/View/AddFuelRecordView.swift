//
//  AddFuelRecordView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import SwiftUI
import SwiftData

struct AddFuelRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext // 注入 ModelContext 以查詢 SwiftData
    @Bindable var vehicle: Vehicle
    
    @State private var date = Date()
    @State private var mileage: String = ""
    @State private var fuelAmount: String = ""
    @State private var cost: String = ""
    @State private var fuelType: FuelType

    // 新增錯誤提示狀態變數
    @State private var showMileageError: Bool = false

    // 儲存從 SwiftData 查詢到的油價
    private let fuelTypeMapping: [FuelType: String] = [
        .gas98: "無鉛汽油98",
        .gas95: "無鉛汽油95",
        .gas92: "無鉛汽油92",
        .diesel: "超級/高級柴油"
    ]

    init(vehicle: Vehicle, fuelPrices: [String: Double]) {
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
                    .onChange(of: date) { calculateFuelCost() } // 日期改變時重新計算
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
                    .onChange(of: fuelType) { calculateFuelCost() } // 油品改變時重新計算
                    HStack {
                        TextField("加油量", text: $fuelAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: fuelAmount) { calculateFuelCost() } // 加油量改變時重新計算
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
        // 將輸入的數據轉為 Double 類型
        let m = Double(mileage) ?? 0
        let f = Double(fuelAmount) ?? 0
        let c = Double(cost) ?? 0

        // 取得按日期排序的紀錄
        let sortedRecords = vehicle.fuelRecords.sorted(by: { $0.date < $1.date })
        let lastRecord = sortedRecords.last

        // 建立新紀錄，初始時 drivenDistance, averageFuelConsumption, costPerKm 設為 0
        let newRecord = FuelRecord(
            date: date,
            mileage: m,
            fuelAmount: f,
            cost: c,
            fuelType: fuelType,
            drivenDistance: 0,
            averageFuelConsumption: 0,
            costPerKm: 0
        )

        // 將新紀錄加入 vehicle.fuelRecords
        vehicle.fuelRecords.append(newRecord)

        // 如果有上一筆紀錄，更新上一筆的 drivenDistance, averageFuelConsumption, costPerKm
        if let lastRecord = lastRecord {
            let distance = m - lastRecord.mileage
            lastRecord.drivenDistance = distance > 0 ? distance : 0
            
            // 計算上一筆的 averageFuelConsumption
            if lastRecord.fuelAmount > 0 {
                lastRecord.averageFuelConsumption = lastRecord.drivenDistance / lastRecord.fuelAmount
            } else {
                lastRecord.averageFuelConsumption = 0
            }
            
            // 計算上一筆的 costPerKm
            if lastRecord.drivenDistance > 0 {
                lastRecord.costPerKm = lastRecord.cost / lastRecord.drivenDistance
            } else {
                lastRecord.costPerKm = 0
            }
        }
    }
    
    private func calculateFuelCost() {
        guard let amount = Double(fuelAmount), amount > 0 else {
            cost = ""
            return
        }
        
        // 根據 date 和 fuelType 從 SwiftData 查詢當天生效的油價
        if let price = fetchFuelPrice(for: fuelType, on: date) {
            let totalCost = amount * price
            cost = String(format: "%.0f", totalCost) // 四捨五入到整數
        } else {
            cost = "" // 若無油價資料，清空 cost
        }
    }
    
    private func fetchFuelPrice(for fuelType: FuelType, on date: Date) -> Double? {
        guard let productName = fuelTypeMapping[fuelType] else { return nil }
        
        do {
            var descriptor = FetchDescriptor<CPCFuelPriceModel>(
                predicate: #Predicate { $0.productName == productName && $0.effectiveDate <= date },
                sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
            )
            descriptor.fetchLimit = 1 // 只取最新的一筆生效油價
            
            let prices = try modelContext.fetch(descriptor)
            if let price = prices.first {
                print("DEBUG: Found price for \(productName) on \(date): \(price.price), EffectiveDate: \(price.effectiveDate)")
                return price.price
            } else {
                print("DEBUG: No price found for \(productName) on \(date)")
                return nil
            }
        } catch {
            print("DEBUG: Error fetching fuel price: \(error)")
            return nil
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Vehicle.self, FuelRecord.self, CPCFuelPriceModel.self)
    let vehicle = Vehicle(name: "Test Car", vehicleType: .car, defaultFuelType: .gas95)
    return AddFuelRecordView(vehicle: vehicle, fuelPrices: [:])
        .modelContainer(container)
}
