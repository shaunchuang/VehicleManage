//
//  ContentView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/15.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    @State private var isShowingAddVehicle = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(vehicles) { vehicle in
                    NavigationLink(
                        destination: VehicleDetailView(vehicle: vehicle)
                    ) {
                        Text(vehicle.name)
                    }
                }
                .onDelete(perform: deleteVehicle)
            }
            .navigationTitle("車輛清單")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        isShowingAddVehicle = true
                    }) {
                        Label("新增車輛", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddVehicle) {
                AddVehicleView()
            }
        } detail: {
            Text("請選擇車輛")
        }
    }

    private func deleteVehicle(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(vehicles[index])
            }
        }
    }
}
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
