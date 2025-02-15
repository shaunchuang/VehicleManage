//
//  AddVehicleView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import SwiftUI

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var defaultFuelType: FuelType = .gas95

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("車輛名稱")) {
                    TextField("請輸入車輛名稱", text: $name)
                }
                Section(header: Text("預設油品")) {
                    Picker(
                        "預設油品",
                        selection: $defaultFuelType
                    ) {
                        ForEach(FuelType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
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
                defaultFuelType: defaultFuelType
            )
            modelContext.insert(newVehicle)
        }
    }
}
