import SwiftUI
import WidgetKit

struct VehicleManageWidgetEntryView: View {
    var entry: FuelEntry
    @Environment(\.widgetFamily) var family

    let gradientBackground = LinearGradient(
        gradient: Gradient(colors: [
            Color(.systemBackground), Color(.systemGray6),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        switch entry.mode {
        case .allFuelPrices:
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 8)
            {
                Text("即時油價")
                    .font(
                        .system(
                            size: family == .systemSmall ? 14 : 16,
                            weight: .bold)
                    )
                    .foregroundStyle(.primary)

                if entry.fuelPrices.isEmpty {
                    Text("無資料")
                        .font(.system(size: family == .systemSmall ? 12 : 14))
                        .foregroundStyle(.secondary)
                } else {
                    let orderedFuelTypes: [FuelType] = [
                        .gas98, .gas95, .gas92, .diesel,
                    ]
                    ForEach(orderedFuelTypes, id: \.self) { fuelType in
                        if let price = entry.fuelPrices[fuelType.rawValue] {
                            HStack(spacing: 8) {
                                Image(systemName: "fuelpump.fill")
                                    .font(
                                        .system(
                                            size: family == .systemSmall
                                                ? 10 : 12)
                                    )
                                    .foregroundStyle(.blue)
                                Text(
                                    fuelType.rawValue.replacingOccurrences(
                                        of: "無鉛", with: "")
                                )
                                .font(
                                    .system(
                                        size: family == .systemSmall ? 12 : 14)
                                )
                                .foregroundStyle(.secondary)
                                Spacer()
                                if family == .systemSmall {
                                    // 小尺寸只顯示當前價格
                                    Text(String(format: "%.2f", price))
                                        .font(
                                            .system(size: 12, weight: .medium)
                                        )
                                        .foregroundStyle(.primary)
                                } else if family == .systemMedium,
                                    let future = entry.futureFuelPrices[
                                        fuelType.rawValue],
                                    future.difference != 0
                                {
                                    HStack(spacing: 4) {
                                                                    Text(String(format: "%.2f", price))
                                                                        .font(.system(size: 14))
                                                                        .foregroundStyle(.primary)
                                                                    Text(diffText(diff: future.difference))
                                                                        .font(.system(size: 14))
                                                                        .foregroundStyle(future.difference > 0 ? .red : .green)
                                                                    Text("→ \(String(format: "%.2f", future.price))")
                                                                        .font(.system(size: 14))
                                                                        .foregroundStyle(.primary)
                                                                }
                                } else {
                                    // 其他尺寸或無漲跌資訊
                                    Text(String(format: "%.2f 元/公升", price))
                                        .font(
                                            .system(size: 14, weight: .medium)
                                        )
                                        .foregroundStyle(.primary)
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
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 8)
            {
                HStack(spacing: 8) {
                    Image(systemName: entry.vehicleType)
                        .font(.system(size: family == .systemSmall ? 14 : 16))
                        .foregroundStyle(.gray)
                    Text(entry.vehicleName)
                        .font(
                            .system(
                                size: family == .systemSmall ? 14 : 16,
                                weight: .bold)
                        )
                        .foregroundStyle(.primary)
                    Spacer()
                }

                HStack(spacing: 8) {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: family == .systemSmall ? 12 : 14))
                        .foregroundStyle(.blue)
                    Text(
                        entry.defaultFuelType.rawValue.replacingOccurrences(
                            of: "無鉛", with: "")
                    )
                    .font(
                        .system(
                            size: family == .systemSmall ? 14 : 16,
                            weight: .medium)
                    )
                    .foregroundStyle(.blue)
                    Spacer()
                    if let price = entry.fuelPrices[
                        entry.defaultFuelType.rawValue]
                    {
                        if family == .systemSmall {
                            // 小尺寸只顯示當前價格
                            Text(String(format: "%.2f", price))
                                .font(.system(size: 12))
                                .foregroundStyle(.primary)
                        } else if family == .systemMedium,
                            let future = entry.futureFuelPrices[
                                entry.defaultFuelType.rawValue],
                            future.difference != 0
                        {
                            // 中尺寸顯示當前價格與漲跌資訊在一行
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.2f", price))
                                    .font(
                                        .system(
                                            size: family == .systemSmall
                                                ? 12 : 14)
                                    )
                                    .foregroundStyle(.primary)
                                Text(
                                    "\(diffText(diff: future.difference)) → \(String(format: "%.2f", future.price))"
                                )
                                .font(
                                    .system(
                                        size: family == .systemSmall ? 10 : 12)
                                )
                                .foregroundStyle(
                                    future.difference > 0 ? .red : .green)
                            }
                        } else {
                            // 其他尺寸或無漲跌資訊
                            Text(String(format: "%.2f 元/公升", price))
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Text("無資料")
                            .font(
                                .system(size: family == .systemSmall ? 12 : 14)
                            )
                            .foregroundStyle(.primary)
                    }
                }

                if family != .systemSmall {
                    Divider().background(Color.gray.opacity(0.3))
                }

                switch family {
                case .systemSmall:
                    VStack(alignment: .leading, spacing: 4) {
                        StatItem(
                            label: "油耗",
                            value: String(
                                format: "%.2f km/L",
                                entry.averageFuelConsumption), icon: "gauge",
                            color: .purple, size: 12)
                        StatItem(
                            label: "里程",
                            value: String(
                                format: "%.1f km", entry.totalMileage),
                            icon: "speedometer", color: .green, size: 12)
                    }
                case .systemMedium:
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ], spacing: 6
                    ) {
                        StatItem(
                            label: "紀錄筆數", value: "\(entry.recordCount)",
                            icon: "list.bullet", color: .purple, size: 14)
                        StatItem(
                            label: "總花費",
                            value: String(format: "$%.0f", entry.totalCost),
                            icon: "dollarsign.circle", color: .orange, size: 14)
                        StatItem(
                            label: "油耗",
                            value: String(
                                format: "%.2f km/L",
                                entry.averageFuelConsumption), icon: "gauge",
                            color: .green, size: 14)
                        StatItem(
                            label: "里程",
                            value: String(
                                format: "%.1f km", entry.totalMileage),
                            icon: "speedometer", color: .blue, size: 14)
                    }
                default:
                    EmptyView()
                }
            }
            .padding(family == .systemSmall ? 8 : 12)
            .containerBackground(gradientBackground, for: .widget)

        case .combined:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: entry.vehicleType)
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                    Text(entry.vehicleName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("即時油價")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    let orderedFuelTypes: [FuelType] = [
                        .gas98, .gas95, .gas92, .diesel,
                    ]
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ], spacing: 6
                    ) {
                        ForEach(orderedFuelTypes, id: \.self) { fuelType in
                            if let price = entry.fuelPrices[fuelType.rawValue] {
                                HStack(spacing: 8) {
                                    Image(systemName: "fuelpump.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.blue)
                                    Text(
                                        fuelType.rawValue.replacingOccurrences(
                                            of: "無鉛", with: "")
                                    )
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    Spacer()
                                    if let future = entry.futureFuelPrices[
                                        fuelType.rawValue],
                                        future.difference != 0
                                    {
                                        VStack(alignment: .trailing, spacing: 2)
                                        {
                                            Text(String(format: "%.2f", price))
                                                .font(
                                                    .system(
                                                        size: 14,
                                                        weight: .medium)
                                                )
                                                .foregroundStyle(.primary)
                                            Text(
                                                "\(diffText(diff: future.difference)) → \(String(format: "%.2f", future.price))"
                                            )
                                            .font(.system(size: 12))
                                            .foregroundStyle(
                                                future.difference > 0
                                                    ? .red : .green)
                                        }
                                    } else {
                                        Text(String(format: "%.2f 元/公升", price))
                                            .font(
                                                .system(
                                                    size: 14, weight: .medium)
                                            )
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                        }
                    }
                }

                Divider().background(Color.gray.opacity(0.3))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                        Text(
                            entry.defaultFuelType.rawValue.replacingOccurrences(
                                of: "無鉛", with: "")
                        )
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                        Spacer()
                        if let price = entry.fuelPrices[
                            entry.defaultFuelType.rawValue],
                            let future = entry.futureFuelPrices[
                                entry.defaultFuelType.rawValue],
                            future.difference != 0
                        {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.2f", price))
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                                Text(
                                    "\(diffText(diff: future.difference)) → \(String(format: "%.2f", future.price))"
                                )
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    future.difference > 0 ? .red : .green)
                            }
                        } else {
                            Text(
                                entry.fuelPrices[entry.defaultFuelType.rawValue]
                                    .map { String(format: "%.2f 元/公升", $0) }
                                    ?? "無資料"
                            )
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                        }
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ], spacing: 6
                    ) {
                        StatItem(
                            label: "紀錄筆數", value: "\(entry.recordCount)",
                            icon: "list.bullet", color: .purple, size: 14)
                        StatItem(
                            label: "總花費",
                            value: String(format: "$%.0f", entry.totalCost),
                            icon: "dollarsign.circle", color: .orange, size: 14)
                        StatItem(
                            label: "總油量",
                            value: String(
                                format: "%.2f L", entry.totalFuelAmount),
                            icon: "fuelpump.fill", color: .green, size: 14)
                        StatItem(
                            label: "總里程",
                            value: String(
                                format: "%.1f km", entry.totalMileage),
                            icon: "speedometer", color: .gray, size: 14)
                        StatItem(
                            label: "平均油耗",
                            value: String(
                                format: "%.2f km/L",
                                entry.averageFuelConsumption), icon: "gauge",
                            color: .teal, size: 14)
                    }
                }
            }
            .padding(12)
            .containerBackground(gradientBackground, for: .widget)
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
