// LoadingView.swift
// VehicleManage
// Created by Shaun Chuang on 2025/2/16.

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            // 可替換為 App logo 或名稱
            Text("油耗紀錄App開啟中")
                .font(.largeTitle)
                .bold()
            ProgressView("讀取中...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
            Spacer()
        }
    }
}
