import SwiftUI
import SwiftData

struct VehicleCardView: View {
    @Bindable var vehicle: Vehicle // 使用 @Bindable 以支援雙向綁定
    let onAddFuel: () -> Void
    let onManage: () -> Void
    
    private let buttonHeight: CGFloat = 36
    
    private var averageConsumption: Double {
        let totalDistance = vehicle.fuelRecords.reduce(0) { $0 + $1.drivenDistance }
        let totalFuel = vehicle.fuelRecords.reduce(0) { $0 + $1.fuelAmount }
        return totalFuel > 0 ? totalDistance / totalFuel : 0
    }
    
    private var currentMileage: Double {
        vehicle.fuelRecords.sorted(by: { $0.date < $1.date }).last?.mileage ?? 0
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) { // 使用 ZStack 將「預設」放在左上角
            VStack(spacing: 8) {
                Image(systemName: vehicle.vehicleType == .car ? "car.side" : "motorcycle")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .foregroundColor(.blue)
                    .scaleEffect(x: vehicle.vehicleType == .car ? -1 : 1, y: 1)
                
                Text(vehicle.name)
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("平均油耗: \(averageConsumption, specifier: "%.2f") 公里/公升")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("目前里程: \(currentMileage, specifier: "%.1f") 公里")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Button(action: onAddFuel) {
                        Label("油耗", systemImage: "plus")
                            .frame(maxWidth: .infinity, minHeight: buttonHeight)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Button(action: onManage) {
                        Label("管理", systemImage: "gear")
                            .frame(maxWidth: .infinity, minHeight: buttonHeight)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .frame(width: 200)
            }
            .padding()
            
            // 左上角的「預設」標籤
            if vehicle.isDefault {
                Text("預設")
                    .font(.system(size: 10))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
                    .offset(x: 16, y: 2) // 調整位置以避免超出邊界
            }
        }
        .frame(width: 210, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .shadow(radius: 2)
    }
}

#Preview {
    // 設置 SwiftData 的記憶體存儲環境
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Vehicle.self, FuelRecord.self, CPCFuelPriceModel.self,
        configurations: config
    )
    let context = container.mainContext
    
    // 創建模擬車輛
    let sampleVehicle = Vehicle(
        name: "我的汽車",
        vehicleType: .car,
        defaultFuelType: .gas95,
        isDefault: true
    )
    
    // 創建模擬油耗記錄
    let fuelRecord1 = FuelRecord(
        date: Date().addingTimeInterval(-86400), // 昨天
        mileage: 1000.0,
        fuelAmount: 40.0,
        cost: 1200.0,
        fuelType: .gas95,
        vehicle: sampleVehicle
    )
    let fuelRecord2 = FuelRecord(
        date: Date(), // 今天
        mileage: 1100.0,
        fuelAmount: 45.0,
        cost: 1350.0,
        fuelType: .gas95,
        vehicle: sampleVehicle
    )
    
    // 將油耗記錄添加到車輛
    sampleVehicle.fuelRecords = [fuelRecord1, fuelRecord2]
    
    // 更新油耗計算
    sampleVehicle.updateFuelRecordCalculations()
    
    // 插入模擬數據到上下文
    context.insert(sampleVehicle)
    
    return VehicleCardView(
        vehicle: sampleVehicle,
        onAddFuel: { print("Add Fuel tapped") },
        onManage: { print("Manage tapped") }
    )
    .modelContainer(container) // 提供 SwiftData 上下文給預覽
}
