import WidgetKit
import SwiftUI

struct FuelConsumptionWidget: Widget {
    let kind: String = "FuelConsumptionWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FuelConsumptionProvider()) { entry in
            VehicleManageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("油耗小工具 - 四種油價")
        .description("顯示所有油價資訊")
        .supportedFamilies([.systemSmall, .systemMedium]) // 移除 Large 尺寸支援
    }
}

struct VehicleManageWidget: Widget {
    let kind: String = "VehicleManageWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VehicleStatsProvider()) { entry in
            VehicleManageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("油耗小工具 - 車輛統計")
        .description("顯示預設油價與車輛統計")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
