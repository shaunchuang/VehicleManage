import SwiftUI

struct VehicleManageWidgetEntryView: View {
    var entry: FuelEntry
    @Environment(\.widgetFamily) var family
    
    let gradientBackground = LinearGradient(
        gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        switch entry.mode {
        case .allFuelPrices:
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 8) {
                Text("即時油價")
                    .font(.system(size: family == .systemSmall ? 14 : 16, weight: .bold))
                    .foregroundStyle(.primary)
                
                if entry.fuelPrices.isEmpty {
                    Text("無資料")
                        .font(.system(size: family == .systemSmall ? 12 : 14))
                        .foregroundStyle(.secondary)
                } else {
                    let orderedFuelTypes: [FuelType] = [.gas98, .gas95, .gas92, .diesel]
                    ForEach(orderedFuelTypes, id: \.self) { fuelType in
                        if let price = entry.fuelPrices[fuelType.rawValue] {
                            HStack(spacing: 8) {
                                Image(systemName: "fuelpump.fill")
                                    .font(.system(size: family == .systemSmall ? 10 : 12))
                                    .foregroundStyle(.blue)
                                Text(fuelType.rawValue.replacingOccurrences(of: "無鉛", with: ""))
                                    .font(.system(size: family == .systemSmall ? 12 : 14))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", price))
                                    .font(.system(size: family == .systemSmall ? 12 : 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                if family != .systemSmall {
                                    Text("元/公升")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                if family != .systemSmall {
                    Spacer()
                }
            }
            .padding(family == .systemSmall ? 8 : 12)
            .containerBackground(gradientBackground, for: .widget)
            
        case .defaultFuelAndStats:
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 8) {
                // 車輛資訊
                HStack(spacing: 8) {
                    Image(systemName: entry.vehicleType)
                        .font(.system(size: family == .systemSmall ? 14 : 16))
                        .foregroundStyle(.gray)
                    Text(entry.vehicleName)
                        .font(.system(size: family == .systemSmall ? 14 : 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                // 預設油品和價格
                HStack(spacing: 8) {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: family == .systemSmall ? 12 : 14))
                        .foregroundStyle(.blue)
                    Text(entry.defaultFuelType.rawValue.replacingOccurrences(of: "無鉛", with: ""))
                        .font(.system(size: family == .systemSmall ? 14 : 16, weight: .medium))
                        .foregroundStyle(.blue)
                    Spacer()
                    Text(entry.fuelPrices[entry.defaultFuelType.rawValue] != nil ? String(format: "%.2f 元/公升", entry.fuelPrices[entry.defaultFuelType.rawValue]!) : "無資料")
                        .font(.system(size: family == .systemSmall ? 12 : 14))
                        .foregroundStyle(.primary)
                }
                
                if family != .systemSmall {
                    Divider().background(Color.gray.opacity(0.3))
                }
                
                switch family {
                case .systemSmall:
                    VStack(alignment: .leading, spacing: 4) {
                        StatItem(label: "油耗", value: String(format: "%.2f km/L", entry.averageFuelConsumption), icon: "gauge", color: .purple, size: 12)
                        StatItem(label: "里程", value: String(format: "%.1f km", entry.totalMileage), icon: "speedometer", color: .green, size: 12)
                    }
                case .systemMedium:
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        StatItem(label: "紀錄筆數", value: "\(entry.recordCount)", icon: "list.bullet", color: .purple, size: 14)
                        StatItem(label: "總花費", value: String(format: "$%.0f", entry.totalCost), icon: "dollarsign.circle", color: .orange, size: 14)
                        StatItem(label: "油耗", value: String(format: "%.2f km/L", entry.averageFuelConsumption), icon: "gauge", color: .green, size: 14)
                        StatItem(label: "里程", value: String(format: "%.1f km", entry.totalMileage), icon: "speedometer", color: .blue, size: 14)
                    }
                default:
                    EmptyView()
                }
            }
            .padding(family == .systemSmall ? 8 : 12)
            .containerBackground(gradientBackground, for: .widget)
            
        case .combined:
            VStack(alignment: .leading, spacing: 8) {
                // 車輛資訊
                HStack(spacing: 8) {
                    Image(systemName: entry.vehicleType)
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                    Text(entry.vehicleName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                // 油價部分
                VStack(alignment: .leading, spacing: 6) {
                    Text("即時油價")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    let orderedFuelTypes: [FuelType] = [.gas98, .gas95, .gas92, .diesel]
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(orderedFuelTypes, id: \.self) { fuelType in
                            if let price = entry.fuelPrices[fuelType.rawValue] {
                                HStack(spacing: 8) {
                                    Image(systemName: "fuelpump.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.blue)
                                    Text(fuelType.rawValue.replacingOccurrences(of: "無鉛", with: ""))
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.2f 元/公升", price))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // 統計數據部分
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                        Text(entry.defaultFuelType.rawValue.replacingOccurrences(of: "無鉛", with: ""))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                        Spacer()
                        Text(entry.fuelPrices[entry.defaultFuelType.rawValue] != nil ? String(format: "%.2f 元/公升", entry.fuelPrices[entry.defaultFuelType.rawValue]!) : "無資料")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        StatItem(label: "紀錄筆數", value: "\(entry.recordCount)", icon: "list.bullet", color: .purple, size: 14)
                        StatItem(label: "總花費", value: String(format: "$%.0f", entry.totalCost), icon: "dollarsign.circle", color: .orange, size: 14)
                        StatItem(label: "總油量", value: String(format: "%.1f L", entry.totalFuelAmount), icon: "fuelpump.fill", color: .green, size: 14)
                        StatItem(label: "範圍里程", value: String(format: "%.1f km", entry.rangeMileage), icon: "road.lanes", color: .blue, size: 14)
                        StatItem(label: "總里程", value: String(format: "%.1f km", entry.totalMileage), icon: "speedometer", color: .gray, size: 14)
                        StatItem(label: "平均油耗", value: String(format: "%.2f km/L", entry.averageFuelConsumption), icon: "gauge", color: .teal, size: 14)
                    }
                }
            }
            .padding(12)
            .containerBackground(gradientBackground, for: .widget)
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: size))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}
