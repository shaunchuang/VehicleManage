import Foundation

class FuelPriceXMLParserDelegate: NSObject, XMLParserDelegate {
    var models: [CPCFuelPriceModel] = []
    private var currentElement: String = ""
    private var currentData: [String: String] = [:]

    func parser(
        _ parser: XMLParser, didStartElement elementName: String,
        namespaceURI: String?, qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "tbTable" {
            currentData = [:]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(
            in: .whitespacesAndNewlines)
        if !trimmedString.isEmpty {
            if let currentValue = currentData[currentElement] {
                currentData[currentElement] = currentValue + trimmedString
            } else {
                currentData[currentElement] = trimmedString
            }
        }
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String,
        namespaceURI: String?, qualifiedName qName: String?
    ) {
        if elementName == "tbTable" {
            guard let productName = currentData["產品名"],
                let priceString = currentData["參考牌價"],
                let price = Double(priceString),
                let dateString = currentData["牌價生效時間"]
            else {
                print("Skipping incomplete record: \(currentData)")
                return
            }

            // 改進日期解析
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withTimeZone]  // 移除 .withFractionalSeconds，加入 .withTimeZone
            guard let effectiveDate = formatter.date(from: dateString) else {
                print("Failed to parse date: \(dateString)")
                return
            }

            let model = CPCFuelPriceModel(
                productName: productName, price: price,
                effectiveDate: effectiveDate)
            models.append(model)
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        print("Parsing completed. Total records: \(models.count)")
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Parse error: \(parseError)")
    }
}
