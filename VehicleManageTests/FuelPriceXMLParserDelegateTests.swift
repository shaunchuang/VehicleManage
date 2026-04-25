//
//  FuelPriceXMLParserDelegateTests.swift
//  VehicleManageTests
//

import Testing
@testable import VehicleManage

import Foundation

struct FuelPriceXMLParserDelegateTests {

    // MARK: - Helpers

    /// Builds a minimal CPC-style XML document from an array of field dictionaries.
    /// Omit a key from the dictionary to simulate a missing field in a `<tbTable>` row.
    private func makeXML(_ rows: [[String: String]]) -> Data {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><NewDataSet>"
        for row in rows {
            xml += "<tbTable>"
            for (key, value) in row {
                xml += "<\(key)>\(value)</\(key)>"
            }
            xml += "</tbTable>"
        }
        xml += "</NewDataSet>"
        return Data(xml.utf8)
    }

    private func parse(_ data: Data) -> [CPCFuelPriceModel] {
        let parser = XMLParser(data: data)
        let delegate = FuelPriceXMLParserDelegate()
        parser.delegate = delegate
        parser.parse()
        return delegate.models
    }

    // MARK: - Valid records

    @Test func parse_validSingleRecord_returnsOneModel() {
        let xml = makeXML([[
            "產品名": "無鉛汽油95",
            "參考牌價": "30.5",
            "牌價生效時間": "2025-02-01T00:00:00+08:00",
        ]])
        let models = parse(xml)
        #expect(models.count == 1)
        #expect(models[0].productName == "無鉛汽油95")
        #expect(models[0].price == 30.5)
    }

    @Test func parse_validMultipleRecords_returnsAllModels() {
        let xml = makeXML([
            ["產品名": "無鉛汽油95", "參考牌價": "30.5", "牌價生效時間": "2025-02-01T00:00:00+08:00"],
            ["產品名": "無鉛汽油92", "參考牌價": "28.9", "牌價生效時間": "2025-02-01T00:00:00+08:00"],
        ])
        let models = parse(xml)
        #expect(models.count == 2)
    }

    @Test func parse_validRecord_dateIsParsedCorrectly() {
        let xml = makeXML([[
            "產品名": "無鉛汽油95",
            "參考牌價": "30.5",
            "牌價生效時間": "2025-02-01T00:00:00+08:00",
        ]])
        let models = parse(xml)
        #expect(models.count == 1)
        // 2025-02-01T00:00:00+08:00 = 2025-01-31T16:00:00Z → Unix 1_738_339_200
        #expect(models[0].effectiveDate.timeIntervalSince1970 == 1_738_339_200)
    }

    // MARK: - Missing required fields

    @Test func parse_missingProductName_skipsRecord() {
        let xml = makeXML([[
            "參考牌價": "30.5",
            "牌價生效時間": "2025-02-01T00:00:00+08:00",
        ]])
        #expect(parse(xml).isEmpty)
    }

    @Test func parse_missingPrice_skipsRecord() {
        let xml = makeXML([[
            "產品名": "無鉛汽油95",
            "牌價生效時間": "2025-02-01T00:00:00+08:00",
        ]])
        #expect(parse(xml).isEmpty)
    }

    @Test func parse_missingDate_skipsRecord() {
        let xml = makeXML([[
            "產品名": "無鉛汽油95",
            "參考牌價": "30.5",
        ]])
        #expect(parse(xml).isEmpty)
    }

    // MARK: - Invalid field values

    @Test func parse_invalidPriceString_skipsRecord() {
        let xml = makeXML([[
            "產品名": "無鉛汽油95",
            "參考牌價": "notANumber",
            "牌價生效時間": "2025-02-01T00:00:00+08:00",
        ]])
        #expect(parse(xml).isEmpty)
    }

    @Test func parse_invalidDateString_skipsRecord() {
        let xml = makeXML([[
            "產品名": "無鉛汽油95",
            "參考牌價": "30.5",
            "牌價生效時間": "not-a-date",
        ]])
        #expect(parse(xml).isEmpty)
    }

    // MARK: - Mixed valid and invalid rows

    @Test func parse_mixedRows_returnsOnlyValidModels() {
        let xml = makeXML([
            ["產品名": "無鉛汽油95", "參考牌價": "30.5", "牌價生效時間": "2025-02-01T00:00:00+08:00"],
            ["產品名": "無鉛汽油95", "參考牌價": "notANumber", "牌價生效時間": "2025-02-01T00:00:00+08:00"],
        ])
        #expect(parse(xml).count == 1)
    }

    // MARK: - Empty input

    @Test func parse_emptyDataSet_returnsNoModels() {
        let xml = makeXML([])
        #expect(parse(xml).isEmpty)
    }
}
