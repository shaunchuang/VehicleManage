import SwiftUI
import Charts

struct FuelConsumptionChartView: View {
    @Bindable var vehicle: Vehicle
    
    @State private var selectedTimeRange: TimeRange = .oneMonth
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customEndDate: Date = Date()
    @State private var selectedChart: ChartType = .fuelConsumption // 新增圖表選擇狀態
    
    // 時間範圍枚舉
    enum TimeRange: String, CaseIterable, Identifiable {
        case oneMonth = "一個月內"
        case threeMonths = "三個月內"
        case oneYear = "一年內"
        case custom = "自定義"
        case all = "全部"
        
        var id: String { self.rawValue }
    }
    
    // 圖表類型枚舉
    enum ChartType: String, CaseIterable, Identifiable {
        case fuelConsumption = "油耗趨勢"
        case fuelCost = "加油金額"
        case distance = "行駛距離"
        
        var id: String { self.rawValue }
    }
    
    // 根據時間範圍篩選紀錄
    var filteredRecords: [FuelRecord] {
        let now = Date()
        let sortedRecords = vehicle.fuelRecords.sorted { $0.date < $1.date }
        switch selectedTimeRange {
        case .oneMonth:
            return sortedRecords.filter { $0.date >= Calendar.current.date(byAdding: .month, value: -1, to: now)! }
        case .threeMonths:
            return sortedRecords.filter { $0.date >= Calendar.current.date(byAdding: .month, value: -3, to: now)! }
        case .oneYear:
            return sortedRecords.filter { $0.date >= Calendar.current.date(byAdding: .year, value: -1, to: now)! }
        case .custom:
            return sortedRecords.filter { $0.date >= customStartDate && $0.date <= customEndDate }
        case .all:
            return sortedRecords
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 時間範圍選擇
                Picker("選擇時間範圍", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 自定義時間範圍的日期選擇器
                if selectedTimeRange == .custom {
                    DatePicker("開始日期", selection: $customStartDate, in: ...Date(), displayedComponents: .date).padding(.horizontal)
                    DatePicker("結束日期", selection: $customEndDate, in: ...Date(), displayedComponents: .date).padding(.horizontal)
                }
                
                // 根據選擇顯示對應圖表
                if !filteredRecords.isEmpty {
                    switch selectedChart {
                    case .fuelConsumption:
                        fuelConsumptionChart
                    case .fuelCost:
                        fuelCostChart
                    case .distance:
                        distanceChart
                    }
                } else {
                    Text("無資料可顯示")
                        .foregroundStyle(.secondary)
                        .padding()
                }
                // 圖表類型選擇
                Picker("選擇圖表", selection: $selectedChart) {
                    ForEach(ChartType.allCases) { chart in
                        Text(chart.rawValue).tag(chart)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 統計數據卡片
                statsCard
                
                Spacer()
            }
        }
        .navigationTitle("油耗趨勢與統計")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 圖表視圖
    
    private var fuelConsumptionChart: some View {
        VStack(alignment: .leading) {
            Text("油耗趨勢 (km/L)")
                .font(.headline)
                .padding(.bottom, 8)
            
            Chart {
                ForEach(filteredRecords.filter { $0.averageFuelConsumption.isFinite }) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("油耗", record.averageFuelConsumption)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value("油耗", record.averageFuelConsumption)
                    )
                    .symbolSize(50)
                    .foregroundStyle(Color.blue)
                    .annotation(position: .top) {
                        Text(String(format: "%.1f", record.averageFuelConsumption))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let dateValue = value.as(Date.self) {
                            Text(dateValue, format: .dateTime.month(.defaultDigits).day())
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let fuelValue = value.as(Double.self) {
                            Text("\(fuelValue, specifier: "%.1f")")
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(height: 250)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var fuelCostChart: some View {
        VStack(alignment: .leading) {
            Text("加油金額趨勢 (NTD)")
                .font(.headline)
                .padding(.bottom, 8)
            
            Chart {
                ForEach(filteredRecords) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("總花費", record.cost)
                    )
                    .foregroundStyle(Color.orange)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value("總花費", record.cost)
                    )
                    .symbolSize(50)
                    .foregroundStyle(Color.orange)
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", record.cost))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let dateValue = value.as(Date.self) {
                            Text(dateValue, format: .dateTime.month(.defaultDigits).day())
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let costValue = value.as(Double.self) {
                            Text("\(costValue, specifier: "%.0f")")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var distanceChart: some View {
        VStack(alignment: .leading) {
            Text("行駛距離趨勢 (km)")
                .font(.headline)
                .padding(.bottom, 8)
            
            Chart {
                ForEach(filteredRecords) { record in
                    BarMark(
                        x: .value("日期", record.date),
                        y: .value("行駛距離", record.drivenDistance)
                    )
                    .foregroundStyle(Color.green)
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", record.drivenDistance))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let dateValue = value.as(Date.self) {
                            Text(dateValue, format: .dateTime.month(.defaultDigits).day())
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let distanceValue = value.as(Double.self) {
                            Text("\(distanceValue, specifier: "%.0f")")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - 統計卡片
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
                Text("車輛統計 - \(vehicle.name)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading)
                ],
                spacing: 12
            ) {
                StatItem(icon: "list.bullet", color: .purple, title: "紀錄筆數", value: "\(filteredRecords.count)")
                StatItem(icon: "dollarsign.circle", color: .orange, title: "總花費", value: String(format: "$%.2f", totalCost(in: filteredRecords)))
                StatItem(icon: "fuelpump.fill", color: .green, title: "總油量", value: String(format: "%.1f L", totalFuelAmount(in: filteredRecords)))
                StatItem(icon: "road.lanes", color: .blue, title: "範圍里程", value: String(format: "%.1f km", totalDistance(in: filteredRecords)))
                StatItem(icon: "gauge", color: .gray, title: "總里程", value: String(format: "%.1f km", currentMileage()))
                StatItem(icon: "chart.line.uptrend.xyaxis", color: .teal, title: "平均油耗", value: String(format: "%.2f km/L", overallAverageConsumption(in: filteredRecords)))
                StatItem(icon: "arrow.up.circle", color: .red, title: "最高油耗", value: String(format: "%.2f km/L", maxConsumption(in: filteredRecords)))
                StatItem(icon: "arrow.down.circle", color: .indigo, title: "最低油耗", value: String(format: "%.2f km/L", minConsumption(in: filteredRecords)))
                StatItem(icon: "creditcard", color: .pink, title: "每公里花費", value: String(format: "%.2f 元/km", averageCostPerKm(in: filteredRecords)))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
    
    // MARK: - 統計計算函式
    
    private func totalCost(in records: [FuelRecord]) -> Double {
        records.reduce(0) { $0 + $1.cost }
    }
    
    private func totalFuelAmount(in records: [FuelRecord]) -> Double {
        records.reduce(0) { $0 + $1.fuelAmount }
    }
    
    private func totalDistance(in records: [FuelRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        let sortedRecords = records.sorted { $0.date < $1.date }
        let firstMileage = sortedRecords.first!.mileage
        let lastMileage = sortedRecords.last!.mileage
        return lastMileage - firstMileage
    }
    
    private func overallAverageConsumption(in records: [FuelRecord]) -> Double {
        let totalDistance = totalDistance(in: records)
        let totalFuel = totalFuelAmount(in: records)
        return totalFuel > 0 ? totalDistance / totalFuel : 0
    }
    
    private func maxConsumption(in records: [FuelRecord]) -> Double {
        records.map { $0.averageFuelConsumption }.max() ?? 0
    }
    
    private func minConsumption(in records: [FuelRecord]) -> Double {
        records.filter { $0.averageFuelConsumption > 0 }.map { $0.averageFuelConsumption }.min() ?? 0
    }
    
    private func averageCostPerKm(in records: [FuelRecord]) -> Double {
        let totalCost = totalCost(in: records)
        let totalDistance = totalDistance(in: records)
        return totalDistance > 0 ? totalCost / totalDistance : 0
    }
    
    private func currentMileage() -> Double {
        vehicle.fuelRecords.sorted { $0.date < $1.date }.last?.mileage ?? 0
    }
}
