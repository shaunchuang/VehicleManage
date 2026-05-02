import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    private var sortedVehicles: [Vehicle] {
        vehicles.sorted { v1, v2 in
            if v1.isDefault && !v2.isDefault { return true }
            if !v1.isDefault && v2.isDefault { return false }
            return v1.name < v2.name
        }
    }

    @State private var fuelPrices: [String: String] = [:]  // 當前油價
    @State private var futureFuelPrices: [String: (price: Double, date: Date)] =
        [:]  // 未來油價及生效日期
    @State private var futureFuelDifferences: [String: Double] = [:]  // 價格差異
    @State private var currentEffectiveDate: Date?  // 當前油價生效日期

    @State private var isShowingAddVehicle = false
    @State private var isShowingAddFuel = false
    @State private var isShowingDetail = false
    @State private var selectedVehicle: Vehicle?

    private let fuelTypeMapping: [String: FuelType] = [
        "無鉛汽油98": .gas98,
        "無鉛汽油95": .gas95,
        "無鉛汽油92": .gas92,
        "超級/高級柴油": .diesel,
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

                            // 調整資訊區塊
                            VStack(alignment: .leading, spacing: 8) {
                                if let effectiveDate = currentEffectiveDate {
                                    Text(
                                        "生效日期：\(dateString(from: effectiveDate))"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                if !futureFuelPrices.isEmpty {
                                    let groupedByDate = Dictionary(
                                        grouping: futureFuelPrices,
                                        by: { $0.value.date })
                                    ForEach(
                                        groupedByDate.keys.sorted(), id: \.self
                                    ) { date in
                                        let adjustments = groupedByDate[date]!
                                        let fuelTypes = adjustments.compactMap {
                                            productName, _ in
                                            fuelTypeMapping[productName]?
                                                .rawValue
                                        }.joined(separator: ", ")
                                        Text(
                                            "未來調整 (\(dateString(from: date)))：\(fuelTypes)"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
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

                    // 車輛清單區塊（不變）
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
                                LazyHStack(spacing: 16) {
                                    ForEach(sortedVehicles) { vehicle in
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
                                    .onMove(perform: moveVehicle)
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 220)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $isShowingAddVehicle) {
                AddVehicleView(onVehicleAdded: { _ in ensureDefaultVehicle() })
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
            .onAppear {
                ensureDefaultVehicle()
            }
        }
    }

    // MARK: - Helper Methods

    private func fuelPriceRow(for fuelType: FuelType) -> some View {
        let productName =
            fuelTypeMapping.first(where: { $0.value == fuelType })?.key ?? ""

        if let diff = futureFuelDifferences[productName], diff != 0,
            let futurePrice = futureFuelPrices[productName]?.price
        {
            return HStack {
                Text(fuelType.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(fuelPrices[productName] ?? "") 元/公升")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(
                        "\(diffText(diff: diff)) → \(String(format: "%.2f", futurePrice))"
                    )
                    .font(.caption)
                    .foregroundStyle(diff > 0 ? .red : .green)
                    .padding(.horizontal, 6)
                    .background(
                        diff > 0
                            ? Color.red.opacity(0.1) : Color.green.opacity(0.1)
                    )
                    .cornerRadius(4)
                }
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
                    sortBy: [
                        SortDescriptor(
                            \CPCFuelPriceModel.effectiveDate, order: .reverse)
                    ]
                )

                let allPrices = try modelContext.fetch(descriptor)
                if let currentPrice = allPrices.first(where: {
                    $0.effectiveDate <= currentDate
                }) {
                    fuelPrices[productName] = String(
                        format: "%.2f", currentPrice.price)
                    if currentEffectiveDate == nil {
                        currentEffectiveDate = currentPrice.effectiveDate
                    }

                    if let futurePrice = allPrices.first(where: {
                        $0.effectiveDate > currentDate
                    }) {
                        let difference = futurePrice.price - currentPrice.price
                        futureFuelDifferences[productName] = difference
                        futureFuelPrices[productName] = (
                            price: futurePrice.price,
                            date: futurePrice.effectiveDate
                        )
                    } else {
                        futureFuelDifferences[productName] = 0
                        futureFuelPrices[productName] = nil
                    }
                }
            }
            // 更新 widget 快取（包含車輛統計與油價資料）
            WidgetCacheUpdater.update(from: modelContext)
            WidgetCenter.shared.reloadAllTimelines()
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

    private func moveVehicle(from source: IndexSet, to destination: Int) {
        var updatedVehicles = vehicles
        updatedVehicles.move(fromOffsets: source, toOffset: destination)

        for (index, vehicle) in updatedVehicles.enumerated() {
            vehicle.isDefault = (index == 0)
        }

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save after moving vehicles: \(error)")
        }
    }

    private func ensureDefaultVehicle() {
        guard !vehicles.isEmpty else { return }

        let hasDefault = vehicles.contains { $0.isDefault }
        if !hasDefault {
            vehicles[0].isDefault = true
            do {
                try modelContext.save()
            } catch {
                print("Failed to set default vehicle: \(error)")
            }
        } else {
            var defaultSet = false
            for vehicle in vehicles {
                if !defaultSet && vehicle.isDefault {
                    defaultSet = true
                } else if vehicle.isDefault {
                    vehicle.isDefault = false
                }
            }
            do {
                try modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("Failed to ensure single default vehicle: \(error)")
            }
        }
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"  // 自訂格式：2025年3月3日
        return formatter.string(from: date)
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
