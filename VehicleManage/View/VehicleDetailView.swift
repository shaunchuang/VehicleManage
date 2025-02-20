import SwiftUI

struct VehicleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    @Bindable var vehicle: Vehicle
    let fuelPrices: [String: Double]

    @State private var isShowingAddFuel = false
    @State private var isShowingDeleteAlert = false
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("車輛名稱")) {
                    TextField("車輛名稱", text: $vehicle.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 4)
                }
                
                Section(header: Text("預設油品")) {
                    Picker("預設油品", selection: $vehicle.defaultFuelType) {
                        ForEach(FuelType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("車輛類型")) {
                    Picker("車輛類型", selection: $vehicle.vehicleType) {
                        ForEach(VehicleType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section {
                    // 查看油耗紀錄
                    NavigationLink(destination: FuelRecordListView(vehicle: vehicle, fuelPrices: fuelPrices)) {
                        Text("查看油耗紀錄")
                    }
                    // 查看油耗圖表
                    NavigationLink(destination: FuelConsumptionChartView(vehicle: vehicle)) {
                        Text("查看油耗圖表")
                    }
                }
                Section {
                    Button(action: {
                        isShowingDeleteAlert = true
                    }) {
                        Text("刪除車輛")
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(.top)

            Spacer()
            
        }
        .navigationTitle("車輛管理")
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text("確認刪除"),
                message: Text("您確定要刪除此車輛嗎？此操作無法撤銷。"),
                primaryButton: .destructive(Text("刪除")) {
                    // 在此處添加刪除車輛的邏輯
                    modelContext.delete(vehicle)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}
