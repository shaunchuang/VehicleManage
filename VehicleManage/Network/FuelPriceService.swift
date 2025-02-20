//
//  FuelPriceService.swift
//  VehicleManage
//
//  Created by Shaun Chuang on 2025/2/18.
//

import Foundation

class FuelPriceService {
    private let apiURL = "https://vipmbr.cpc.com.tw/cpcstn/listpricewebservice.asmx/getCPCMainProdListPrice_Historical"

    /// 發送 `POST` 請求並解析 XML 回應
    func fetchPrice(for fuelId: String, fuelName: String) async -> [(String, Double, String)] {
        guard let url = URL(string: apiURL) else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "prodid=\(fuelId)".data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try parseAllFuelPrices(from: data, fuelName: fuelName)
        } catch {
            print("獲取油價失敗: \(error)")
            return []
        }
    }

    /// 解析 API 回應的 XML
    private func parseAllFuelPrices(from data: Data, fuelName: String) throws -> [(String, Double, String)] {
        print("parseAllFuelPrices")
        print("data", data)
        print("fuelName", fuelName)
        let xml = String(data: data, encoding: .utf8) ?? ""
        let tbTableRegex = try NSRegularExpression(pattern: "(?s)<tbTable.*?>(.*?)</tbTable>", options: [])
        let fullRange = NSRange(location: 0, length: xml.utf16.count)
        let matches = tbTableRegex.matches(in: xml, range: fullRange)

        let datePattern = try NSRegularExpression(pattern: "<牌價生效時間>(.*?)</牌價生效時間>", options: [])
        let pricePattern = try NSRegularExpression(pattern: "<參考牌價>(.*?)</參考牌價>", options: [])
        let productPattern = try NSRegularExpression(pattern: "<產品名>(.*?)</產品名>", options: [])

        var results = [(String, Double, String)]()

        for match in matches {
            let tbTableRange = match.range(at: 1)
            guard let rangeInXML = Range(tbTableRange, in: xml) else { continue }
            let tbTableContent = String(xml[rangeInXML])

            let dateString = extractValue(from: tbTableContent, using: datePattern) ?? "未知"
            let priceString = extractValue(from: tbTableContent, using: pricePattern) ?? "0.0"
            let productString = extractValue(from: tbTableContent, using: productPattern) ?? fuelName
            let priceValue = Double(priceString) ?? 0.0
            print("dataString ", dateString)
            print("priceValue ", priceValue)
            print("productString ", productString)
            results.append((productString, priceValue, dateString))
        }
        return results
    }

    private func extractValue(from text: String, using regex: NSRegularExpression) -> String? {
        if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)) {
            if let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        return nil
    }
}
