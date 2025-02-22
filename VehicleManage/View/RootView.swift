// RootView.swift
// VehicleManage
// Created by Shaun Chuang on 2025/2/21.

import SwiftData
import SwiftUI

struct RootView: View {
    let modelContainer: ModelContainer
    @Binding var lastFetchDate: Double // 綁定 AppStorage 的 lastFetchDate
    @State private var isLoading = true // 控制是否顯示載入畫面

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .modelContainer(modelContainer)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: isLoading) // 添加切換動畫
        .task {
            let now = Date().timeIntervalSince1970
            let oneDayInSeconds: Double = 24 * 60 * 60 // 一天的秒數
            if now - lastFetchDate > oneDayInSeconds {
                await FuelPriceManager(context: modelContainer.mainContext).fetchDataFromCPCAPI()
                lastFetchDate = now // 更新抓取時間
            } else {
                print("DEBUG: 距離上次更新不到一天，跳過抓取資料")
            }
            // 無論是否抓取資料，任務完成後設置 isLoading 為 false
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
