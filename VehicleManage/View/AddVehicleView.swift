import SwiftUI
import SwiftData
import WidgetKit

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var vehicleType: VehicleType = .car
    @State private var defaultFuelType: FuelType = .gas95
    @State private var isDefault: Bool = false
    
    var onVehicleAdded: ((Vehicle) -> Void)?

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
                Section {
                    Toggle("設為預設車輛", isOn: $isDefault)
                }
            }
            .navigationTitle("新增車輛")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveVehicle() }
                }
            }
        }
    }

    private func saveVehicle() {
        withAnimation {
            let newVehicle = Vehicle(
                name: name.isEmpty ? "新車輛" : name,
                vehicleType: vehicleType,
                defaultFuelType: defaultFuelType,
                isDefault: isDefault
            )
            modelContext.insert(newVehicle)
            
            if isDefault {
                clearOtherDefaults(except: newVehicle)
            }
            
            do {
                try modelContext.save()
                onVehicleAdded?(newVehicle)
                WidgetCacheUpdater.update(from: modelContext)
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("Failed to save vehicle: \(error.localizedDescription)")
            }
            dismiss()
        }
    }
    
    private func clearOtherDefaults(except vehicle: Vehicle) {
        let fetchDescriptor = FetchDescriptor<Vehicle>()
        guard let allVehicles = try? modelContext.fetch(fetchDescriptor) else { return }
        
        for otherVehicle in allVehicles {
            if otherVehicle.id != vehicle.id {
                otherVehicle.isDefault = false
            }
        }
    }
}
