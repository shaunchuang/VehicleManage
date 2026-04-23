import Foundation

extension FuelType {
    /// CPC API/DB productName used in `CPCFuelPriceModel.productName`.
    var cpcProductName: String {
        switch self {
        case .gas98: return "無鉛汽油98"
        case .gas95: return "無鉛汽油95"
        case .gas92: return "無鉛汽油92"
        case .diesel: return "超級/高級柴油"
        }
    }

    /// Reverse mapping from CPC product name to `FuelType`.
    static func fromCPCProductName(_ name: String) -> FuelType? {
        switch name {
        case "無鉛汽油98": return .gas98
        case "無鉛汽油95": return .gas95
        case "無鉛汽油92": return .gas92
        case "超級/高級柴油": return .diesel
        default: return nil
        }
    }

    static var allCPCProductNames: [String] {
        FuelType.allCases.map { $0.cpcProductName }
    }
}
