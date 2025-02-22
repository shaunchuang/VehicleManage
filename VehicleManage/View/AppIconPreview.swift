import SwiftUI

struct ShengYouTongIconPreview: View {
    var body: some View {
        ZStack {
            // 背景線性漸層
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "BFDBFE"), Color(hex: "CCFBE2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 汽車
            Image(systemName: "car.side")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.white)
                .shadow(color: .gray.opacity(0.2), radius: 3, x: 2, y: 2)
                .offset(x: -80, y: -80)
            
            // 機車
            Image(systemName: "motorcycle")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.white)
                .shadow(color: .gray.opacity(0.2), radius: 3, x: 2, y: 2)
                .offset(x: 70, y: 70)
            
            // 油滴
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color(hex: "86EFAC"))
                .shadow(color: .gray.opacity(0.2), radius: 3, x: 2, y: 2)
                .offset(y: 20)
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 60, style: .continuous))
        .shadow(radius: 5)
    }
}

// 顏色擴展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}

#Preview {
    ShengYouTongIconPreview()
}
