//
//  FuelConsumptionChartView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/16.
//
import SwiftUI
import Charts

struct FuelConsumptionChartView: View {
    @Bindable var vehicle: Vehicle
    
    @State private var selectedTimeRange: TimeRange = .oneMonth
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case oneMonth = "一個月內"
        case threeMonths = "三個月內"
        case oneYear = "一年內"
        case custom = "自定義"
        case all = "全部"
        
        var id: String { self.rawValue }
    }
    
    var filteredRecords: [FuelRecord] {
        let now = Date()
        switch selectedTimeRange {
        case .oneMonth:
            return vehicle.fuelRecords.filter {
                $0.date >= Calendar.current.date(byAdding: .month, value: -1, to: now)!
            }
        case .threeMonths:
            return vehicle.fuelRecords.filter {
                $0.date >= Calendar.current.date(byAdding: .month, value: -3, to: now)!
            }
        case .oneYear:
            return vehicle.fuelRecords.filter {
                $0.date >= Calendar.current.date(byAdding: .year, value: -1, to: now)!
            }
        case .custom:
            // 可自行實作自訂時間區間的篩選邏輯
            return vehicle.fuelRecords
        case .all:
            return vehicle.fuelRecords
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 顯示圖表標題
                Text("油耗趨勢與統計")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                // 時間範圍切換
                Picker("選擇時間範圍", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 主圖表卡片
                VStack(alignment: .leading) {
                    Text("油耗趨勢 (km/L)")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Chart {
                        ForEach(aggregatedData(), id: \.id) { dataPoint in
                            
                            // 以月或指定區間為單位的面積區域，增加漸層視覺
                            AreaMark(
                                x: .value("日期", dataPoint.date),
                                y: .value("油耗", dataPoint.fuelConsumption)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.05)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            
                            // 線圖
                            LineMark(
                                x: .value("日期", dataPoint.date),
                                y: .value("油耗", dataPoint.fuelConsumption)
                            )
                            .foregroundStyle(Color.blue)
                            .interpolationMethod(.catmullRom)
                            
                            // 圓點標記
                            PointMark(
                                x: .value("日期", dataPoint.date),
                                y: .value("油耗", dataPoint.fuelConsumption)
                            )
                            .symbolSize(30)
                            .foregroundStyle(Color.blue)
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
                .background(.ultraThinMaterial) // 半透明背景，可改成 Color(.systemBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 追加「金額」折線圖 (可自由增減)
                if !filteredRecords.isEmpty {
                    VStack(alignment: .leading) {
                        Text("加油金額趨勢 (NTD)")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        Chart {
                            ForEach(aggregatedData(), id: \.id) { dataPoint in
                                LineMark(
                                    x: .value("日期", dataPoint.date),
                                    y: .value("總花費", dataPoint.totalCost)
                                )
                                .foregroundStyle(Color.orange)
                                .interpolationMethod(.catmullRom)
                                
                                PointMark(
                                    x: .value("日期", dataPoint.date),
                                    y: .value("總花費", dataPoint.totalCost)
                                )
                                .symbolSize(30)
                                .foregroundStyle(Color.orange)
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
                
                // 統計數據卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("車輛名稱：\(vehicle.name)")
                    Text("油耗紀錄筆數：\(filteredRecords.count)")
                    Text("總花費：$\(totalCost(in: filteredRecords), specifier: "%.2f")")
                    Text("總油量：\(totalFuelAmount(in: filteredRecords), specifier: "%.1f") L")
                    Text("目前里程：\(currentMileage(), specifier: "%.1f") 公里")
                    Text("平均油耗：\(overallAverageConsumption(in: filteredRecords), specifier: "%.2f") km/L")
                    Text("最高油耗：\(maxConsumption(in: filteredRecords), specifier: "%.2f") km/L")
                    Text("最低油耗：\(minConsumption(in: filteredRecords), specifier: "%.2f") km/L")
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("油耗圖表")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 資料聚合：可自行加強時間分段的邏輯
    private func aggregatedData() -> [AggregatedData] {
        // 先將記錄做時間排序，再根據時間範圍篩選
        let records = filteredRecords.sorted { $0.date < $1.date }
        
        // 這裡仍以「月份」作為聚合範例，如需更細或更粗的區間，可再調整
        let grouped = Dictionary(grouping: records) { record -> Date in
            // 將日期轉成當月第一天，作為分組 key
            let comps = Calendar.current.dateComponents([.year, .month], from: record.date)
            return Calendar.current.date(from: comps) ?? record.date
        }
        
        // 對每個月的紀錄做統計，包含平均油耗、總花費等
        return grouped.keys.sorted().map { monthStart in
            let monthRecords = grouped[monthStart]!
            let totalDistance = monthRecords.reduce(0) { $0 + $1.drivenDistance }
            let totalFuel = monthRecords.reduce(0) { $0 + $1.fuelAmount }
            let consumption = totalFuel > 0 ? totalDistance / totalFuel : 0
            let totalCost = monthRecords.reduce(0) { $0 + $1.cost }
            
            return AggregatedData(
                date: monthStart,
                periodLabel: monthStart.formatted(.dateTime.year().month()),
                fuelConsumption: consumption,
                totalCost: totalCost
            )
        }
    }
    
    // MARK: - 統計計算函式（針對「篩選後」的記錄）
    private func totalCost(in records: [FuelRecord]) -> Double {
        records.reduce(0) { $0 + $1.cost }
    }
    
    private func totalFuelAmount(in records: [FuelRecord]) -> Double {
        records.reduce(0) { $0 + $1.fuelAmount }
    }
    
    private func overallAverageConsumption(in records: [FuelRecord]) -> Double {
        let totalDistance = records.reduce(0) { $0 + $1.drivenDistance }
        let totalFuel = records.reduce(0) { $0 + $1.fuelAmount }
        return totalFuel > 0 ? totalDistance / totalFuel : 0
    }
    
    private func maxConsumption(in records: [FuelRecord]) -> Double {
        records.map { $0.averageFuelConsumption }.max() ?? 0
    }
    
    private func minConsumption(in records: [FuelRecord]) -> Double {
        records.map { $0.averageFuelConsumption }.min() ?? 0
    }
    
    private func currentMileage() -> Double {
        vehicle.fuelRecords.sorted { $0.date < $1.date }.last?.mileage ?? 0
    }
}

// MARK: - 新增 AggregatedData 結構，含 totalCost
struct AggregatedData: Identifiable {
    let id = UUID()
    let date: Date
    let periodLabel: String
    let fuelConsumption: Double
    let totalCost: Double
}

