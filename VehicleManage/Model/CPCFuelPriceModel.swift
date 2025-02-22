//
//  CPCFuelPriceModel.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/18.
//
import Foundation
import SwiftData

@Model class CPCFuelPriceModel {
    @Attribute(.unique) var id: UUID = UUID()
    var productName: String
    var price: Double
    var effectiveDate: Date

    init(productName: String, price: Double, effectiveDate: Date) {
        self.productName = productName
        self.price = price
        self.effectiveDate = effectiveDate
    }
}
