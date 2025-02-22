import SwiftUI
import Charts

struct FuelConsumptionChartView: View {
    @Bindable var vehicle: Vehicle
    
    @State private var selectedTimeRange: TimeRange = .oneMonth
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customEndDate: Date = Date()
    
    // 時間範圍枚舉
    enum TimeRange: String, CaseIterable, Identifiable {
        case oneMonth = "一個月內"
        case threeMonths = "三個月內"
        case oneYear = "一年內"
        case custom = "自定義"
        case all = "全部"
        
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
                    DatePicker("開始日期", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("結束日期", selection: $customEndDate, displayedComponents: .date)
                }
                
                // 油耗趨勢圖表
                VStack(alignment: .leading) {
                    Text("油耗趨勢 (km/L)")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Chart {
                        ForEach(filteredRecords) { record in
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
                
                // 加油金額趨勢圖表
                if !filteredRecords.isEmpty {
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
                
                // 行駛距離趨勢圖表
                if !filteredRecords.isEmpty {
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
                
                // 統計數據卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("車輛名稱：\(vehicle.name)")
                    Text("油耗紀錄筆數：\(filteredRecords.count)")
                    Text("總花費：$\(totalCost(in: filteredRecords), specifier: "%.2f")")
                    Text("總油量：\(totalFuelAmount(in: filteredRecords), specifier: "%.1f") L")
                    Text("範圍內總里程變化：\(totalDistance(in: filteredRecords), specifier: "%.1f") 公里")
                    Text("目前總里程：\(currentMileage(), specifier: "%.1f") 公里")
                    Text("平均油耗：\(overallAverageConsumption(in: filteredRecords), specifier: "%.2f") km/L")
                    Text("最高油耗：\(maxConsumption(in: filteredRecords), specifier: "%.2f") km/L")
                    Text("最低油耗：\(minConsumption(in: filteredRecords), specifier: "%.2f") km/L")
                    Text("平均每公里花費：\(averageCostPerKm(in: filteredRecords), specifier: "%.2f") 元/km")
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("油耗趨勢與統計")
        .navigationBarTitleDisplayMode(.inline)
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
