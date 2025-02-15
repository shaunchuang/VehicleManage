//
//  VehicleCardView.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/16.
//
import SwiftUI

struct VehicleCardView: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onAddFuel: () -> Void
    let onManage: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    // 車輛圖示
                    Image(systemName: "car.side")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80) // 縮小圖示
                        .foregroundColor(.blue)

                    // 車輛名稱
                    Text(vehicle.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .orange : .primary)
                }
                .padding()
                .frame(width: 180, height: 160) // 調整大小
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.orange : .clear, lineWidth: 2)
                )
                .shadow(radius: 2)
                .onTapGesture {
                    onSelect()
                }

                // 右上角刪除按鈕
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
                .offset(x: -10, y: 10)
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("刪除車輛"),
                        message: Text("請問是否刪除此車輛資料？"),
                        primaryButton: .destructive(Text("刪除")) {
                            onDelete()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }

            // 下方按鈕區域
            HStack {
                Button(action: onAddFuel) {
                    Label("油耗", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: onManage) {
                    Label("管理", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .frame(width: 180) // 調整按鈕寬度
        }
    }
}
