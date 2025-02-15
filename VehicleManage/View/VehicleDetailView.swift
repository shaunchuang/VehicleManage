//
//  VehicleDetailView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import SwiftUI

struct VehicleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var vehicle: Vehicle

    @State private var isShowingAddFuel = false

    var body: some View {
        VStack {
            Form {
                Section(header: Text("車輛名稱")) {
                    TextField("車輛名稱", text: $vehicle.name)
                }
                Section(header: Text("預設油品")) {
                    Picker(
                        "預設油品",
                        selection: $vehicle.defaultFuelType
                    ) {
                        ForEach(FuelType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
            .frame(height: 200)
            HStack {
                Text("油耗紀錄")
                    .font(.headline)
                Spacer()
                Button("+新增油耗紀錄"){
                    isShowingAddFuel = true
                    
                }
            }.padding(.horizontal)

            List {
                ForEach(vehicle.fuelRecords) { record in
                    VStack(alignment: .leading) {
                        Text("日期: \(record.date, format: .dateTime.year().month().day())")
                        Text("里程數: \(record.mileage, specifier: "%.1f") 公里")
                        Text("加油量: \(record.fuelAmount, specifier: "%.1f") 公升")
                        Text("金額: $\(record.cost, specifier: "%.0f")")
                        Text("油品: \(record.fuelType.rawValue)")
                    }
                }
                .onDelete(perform: deleteRecord)
            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(role: .destructive) {
//                        deleteVehicle()
//                    } label: {
//                        Label("刪除車輛", systemImage: "trash")
//                    }
//                }
//            }

        }
//        .navigationTitle(vehicle.name)
        .navigationTitle("車輛管理")
        .sheet(isPresented: $isShowingAddFuel) {
            AddFuelRecordView(vehicle: vehicle)
        }
    }

    private func deleteRecord(offsets: IndexSet) {
        withAnimation {
            vehicle.fuelRecords.remove(atOffsets: offsets)
        }
    }
    


}

