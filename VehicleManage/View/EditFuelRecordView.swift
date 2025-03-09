import SwiftData
import SwiftUI
import WidgetKit

struct EditFuelRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var record: FuelRecord
    @Bindable var vehicle: Vehicle

    @State private var date: Date
    @State private var mileage: String
    @State private var fuelAmount: String
    @State private var cost: String
    @State private var fuelType: FuelType
    @State private var unitPrice: Double? = nil // 新增單價狀態

    private let fuelTypeMapping: [FuelType: String] = [
        .gas98: "無鉛汽油98",
        .gas95: "無鉛汽油95",
        .gas92: "無鉛汽油92",
        .diesel: "超級/高級柴油",
    ]

    private var dateRange: ClosedRange<Date> {
        let sortedRecords = vehicle.fuelRecords.sorted { $0.date < $1.date }
        guard let currentIndex = sortedRecords.firstIndex(where: { $0.id == record.id }) else {
            return Date.distantPast...Date.distantFuture
        }

        let minDate = currentIndex > 0 ? sortedRecords[currentIndex - 1].date : Date.distantPast
        let maxDate = currentIndex < sortedRecords.count - 1 ? sortedRecords[currentIndex + 1].date : Date.distantFuture
        
        let calendar = Calendar.current
        let startOfMinDate = calendar.startOfDay(for: minDate)
        let endOfMaxDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: maxDate) ?? maxDate
        
        return startOfMinDate...endOfMaxDate
    }

    init(record: FuelRecord, vehicle: Vehicle) {
        self.record = record
        self.vehicle = vehicle
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
                    DatePicker(
                        "日期",
                        selection: $date,
                        in: dateRange,
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
                        TextField("加油量（公升）", text: $fuelAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: fuelAmount) { calculateFuelCost() }
                        Text("公升")
                            .foregroundColor(.secondary)
                    }
                    // 顯示當前油價
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
            .navigationTitle("編輯油耗紀錄")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(!isValidInput())
                }
            }
            .onAppear {
                calculateFuelCost() // 初始化單價
            }
        }
    }

    private func saveChanges() {
        let m = Double(mileage) ?? record.mileage
        let f = Double(fuelAmount) ?? record.fuelAmount
        let c = Double(cost) ?? record.cost

        record.date = date
        record.mileage = m
        record.fuelAmount = f
        record.cost = c
        record.fuelType = fuelType

        vehicle.updateFuelRecordCalculations()
        
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save edited fuel record: \(error)")
        }
    }

    private func calculateFuelCost() {
        guard let amount = Double(fuelAmount), amount > 0 else {
            cost = ""
            unitPrice = nil
            return
        }

        if let price = fetchFuelPrice(for: fuelType, on: date) {
            unitPrice = price // 更新單價
            let totalCost = amount * price
            cost = String(format: "%.0f", totalCost)
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

    private func isValidInput() -> Bool {
        return Double(mileage) != nil && Double(fuelAmount) != nil && Double(cost) != nil
    }
}
