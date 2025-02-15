//
//  OilPriceInfo.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/16.
//

import Foundation

struct CPCFuelPrice: Codable {
    let productName: String    // "產品名稱"
    let price: Double          // "參考牌價"

    enum CodingKeys: String, CodingKey {
        case productName = "產品名稱"
        case price = "參考牌價"
    }
}


