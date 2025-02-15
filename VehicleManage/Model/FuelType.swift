//
//  FuelType.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import Foundation
    
    enum FuelType: String, CaseIterable, Identifiable {
        case gas92 = "92無鉛"
        case gas95 = "95無鉛"
        case gas98 = "98無鉛"
        case diesel = "柴油"

        var id: String {
            self.rawValue
        }
    }


    

