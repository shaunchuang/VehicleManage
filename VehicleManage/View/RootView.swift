import SwiftData
import SwiftUI
import WidgetKit

struct RootView: View {
    let modelContainer: ModelContainer
    @Binding var lastFetchDate: Double // 綁定 AppStorage 的 lastFetchDate
    @State private var isLoading = true // 控制是否顯示載入畫面
    @Environment(\.scenePhase) private var scenePhase // 監聽場景階段

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
            // 應用啟動時檢查並抓取資料
            await checkAndFetchFuelPrices()
            await MainActor.run {
                isLoading = false
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase == .background && newPhase == .active {
                // 僅在從背景回到前台時執行
                Task {
                    await MainActor.run { isLoading = true }
                    await checkAndFetchFuelPrices()
                    await MainActor.run { isLoading = false }
                }
            }
        }
    }

    // 檢查並抓取油價的共用方法
    private func checkAndFetchFuelPrices() async {
        let now = Date().timeIntervalSince1970
        let oneDayInSeconds: Double = 24 * 60 * 60 // 一天的秒數
        if now - lastFetchDate > oneDayInSeconds {
            print("DEBUG: 超過一天未更新，執行 CPC API 抓取")
            await FuelPriceManager(context: modelContainer.mainContext).fetchDataFromCPCAPI()
            lastFetchDate = now // 更新抓取時間
            // 油價更新後同步刷新 widget 快取
            await MainActor.run {
                WidgetCacheUpdater.update(from: modelContainer.mainContext)
            }
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("DEBUG: 距離上次更新不到一天，跳過抓取資料")
        }
    }

}


