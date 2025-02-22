//
//  StatItem.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/22.
//

import SwiftUI

struct StatItem: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
    }
}

