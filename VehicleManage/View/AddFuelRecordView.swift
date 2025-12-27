import SwiftData
import SwiftUI
import WidgetKit

struct AddFuelRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var vehicle: Vehicle

    @State private var date = Date()
    @State private var mileage: String = ""
    @State private var fuelAmount: String = ""
    @State private var cost: String = ""
    @State private var fuelType: FuelType
    @State private var unitPrice: Double? = nil
    @State private var showMileageError: Bool = false

    private let fuelTypeMapping: [FuelType: String] = [
        .gas98: "無鉛汽油98",
        .gas95: "無鉛汽油95",
        .gas92: "無鉛汽油92",
        .diesel: "超級/高級柴油",
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
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "zh-Hant-TW"))
                    .onChange(of: date) { calculateFuelCost() }
                    HStack {
                        TextField("總里程數（公里）", text: $mileage)
                            .keyboardType(.decimalPad)
                        Text("公里")
                            .foregroundColor(.secondary)
                    }
                }
                Section(header: Text("加油資訊")) {
                    Picker("油品種類", selection: $fuelType) {
                        ForEach(FuelType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: fuelType) { calculateFuelCost() }
                    
                    HStack {
                        TextField("加油量", text: $fuelAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: fuelAmount) { calculateFuelCost() }
                        Text("公升")
                            .foregroundColor(.secondary)
                    }
                    
                    if let price = unitPrice {
                        Text("單價：\(String(format: "%.2f", price)) 元/公升")
                            .foregroundColor(.secondary)
                    } else {
                        Text("單價：無可用油價")
                            .foregroundColor(.red)
                    }
                }
                Section {
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
                    Button("取消") { dismiss() }
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
            .alert(
                "里程數錯誤", isPresented: $showMileageError,
                actions: { Button("確定", role: .cancel) {} },
                message: { Text("總里程數必須大於上一筆紀錄的總里程數") }
            )
            .onAppear {
                calculateFuelCost() // 初始化單價
            }
        }
    }

    private func saveRecord() {
        let m = Double(mileage) ?? 0
        let f = Double(fuelAmount) ?? 0
        let c = Double(cost) ?? 0

        let newRecord = FuelRecord(
            date: date,
            mileage: m,
            fuelAmount: f,
            cost: c,
            fuelType: fuelType,
            drivenDistance: 0,
            averageFuelConsumption: 0,
            costPerKm: 0,
            vehicle: vehicle
        )

        vehicle.fuelRecords.append(newRecord)

        // 使用集中邏輯重新計算所有紀錄，避免與其他地方的重複與不一致
        vehicle.updateFuelRecordCalculations()
        
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save fuel record: \(error)")
        }
    }

    private func calculateFuelCost() {
        // 即使 fuelAmount 為空，也查詢並顯示單價
        if let price = fetchFuelPrice(for: fuelType, on: date) {
            unitPrice = price
            if let amount = Double(fuelAmount), amount > 0 {
                let totalCost = amount * price
                cost = String(format: "%.0f", totalCost)
            } else {
                cost = ""
            }
        } else {
            unitPrice = nil
            cost = ""
        }
    }

    private func fetchFuelPrice(for fuelType: FuelType, on date: Date) -> Double? {
        guard let productName = fuelTypeMapping[fuelType] else { return nil }

        do {
            var descriptor = FetchDescriptor<CPCFuelPriceModel>(
                predicate: #Predicate { $0.productName == productName && $0.effectiveDate <= date },
                sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
            )
            descriptor.fetchLimit = 1

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
