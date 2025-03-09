// LoadingView.swift
// VehicleManage
// Created by Shaun Chuang on 2025/2/16.

import SwiftUI

// 載入畫面視圖
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Text("正在更新油價資料...")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
