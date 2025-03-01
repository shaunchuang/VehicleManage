//
//  FuelType.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import Foundation

// FuelType.swift (假設這是您的 FuelType 定義)
enum FuelType: String, CaseIterable, Identifiable, Codable { // 添加 Codable
    case gas92 = "92無鉛"
    case gas95 = "95無鉛"
    case gas98 = "98無鉛"
    case diesel = "超級柴油"
    
    var id: String { self.rawValue }
}
