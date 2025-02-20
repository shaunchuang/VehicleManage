//
//  VehicleCardView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/16.
//
// VehicleCardView.swift
import SwiftUI

struct VehicleCardView: View {
    let vehicle: Vehicle
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
        .frame(width: 210, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .shadow(radius: 2)
    }
}
