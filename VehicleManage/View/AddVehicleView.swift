import SwiftUI

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var vehicleType: VehicleType = .car
    @State private var defaultFuelType: FuelType = .gas95

    var body: some View {
        NavigationStack {
                Form {
                    Section(header: Text("車輛名稱")) {
                        TextField("請輸入車輛名稱", text: $name)
                    }
                    Section(header: Text("車輛類型")) {
                        Picker("選擇車輛類型", selection: $vehicleType) {
                            ForEach(VehicleType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    Section(header: Text("預設油品")) {
                        Picker("預設油品", selection: $defaultFuelType) {
                            ForEach(FuelType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }.ignoresSafeArea(.keyboard)
            
            .navigationTitle("新增車輛")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        addVehicle()
                        dismiss()
                    }
                }
            }
        }
    }

    private func addVehicle() {
        withAnimation {
            let newVehicle = Vehicle(
                name: name.isEmpty ? "新車輛" : name,
                vehicleType: vehicleType,
                defaultFuelType: defaultFuelType
            )
            modelContext.insert(newVehicle)
            do {
                try modelContext.save()
                print("Vehicle saved: \(newVehicle.name), ID: \(newVehicle.id)")
            } catch {
                print("Failed to save vehicle: \(error.localizedDescription)")
            }
        }
    }
}
