import Foundation

enum AppFormatters {
    static let zhTWDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hant-TW")
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    static func dateString(_ date: Date) -> String {
        zhTWDate.string(from: date)
    }

    static func decimalString(_ value: Double, digits: Int) -> String {
        String(format: "%0.*f", digits, value)
    }

    static func currency0(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    static func price2(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
