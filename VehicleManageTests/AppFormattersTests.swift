//
//  AppFormattersTests.swift
//  VehicleManageTests
//

import Testing
@testable import VehicleManage

import Foundation

struct AppFormattersTests {

    // MARK: - decimalString

    @Test func decimalString_zeroDigits_roundsUp() {
        #expect(AppFormatters.decimalString(3.7, digits: 0) == "4")
    }

    @Test func decimalString_zeroDigits_roundsDown() {
        #expect(AppFormatters.decimalString(3.2, digits: 0) == "3")
    }

    @Test func decimalString_twoDigits_paddedZero() {
        #expect(AppFormatters.decimalString(3.1, digits: 2) == "3.10")
    }

    @Test func decimalString_twoDigits_exact() {
        #expect(AppFormatters.decimalString(3.14, digits: 2) == "3.14")
    }

    @Test func decimalString_oneDigit_negative() {
        #expect(AppFormatters.decimalString(-5.6, digits: 1) == "-5.6")
    }

    @Test func decimalString_zero() {
        #expect(AppFormatters.decimalString(0, digits: 2) == "0.00")
    }

    // MARK: - currency0

    @Test func currency0_roundsDown() {
        #expect(AppFormatters.currency0(999.4) == "999")
    }

    @Test func currency0_roundsUp() {
        #expect(AppFormatters.currency0(999.6) == "1000")
    }

    @Test func currency0_exactInteger() {
        #expect(AppFormatters.currency0(500.0) == "500")
    }

    @Test func currency0_zero() {
        #expect(AppFormatters.currency0(0) == "0")
    }

    @Test func currency0_negativeValue() {
        #expect(AppFormatters.currency0(-100.7) == "-101")
    }

    // MARK: - price2

    @Test func price2_paddedZero() {
        #expect(AppFormatters.price2(30.1) == "30.10")
    }

    @Test func price2_exactTwoDecimals() {
        #expect(AppFormatters.price2(32.50) == "32.50")
    }

    @Test func price2_zero() {
        #expect(AppFormatters.price2(0) == "0.00")
    }

    @Test func price2_negativeValue() {
        #expect(AppFormatters.price2(-1.5) == "-1.50")
    }

    // MARK: - dateString

    @Test func dateString_containsChineseDateMarkers() {
        let date = Date(timeIntervalSince1970: 0)
        let result = AppFormatters.dateString(date)
        #expect(result.contains("年"))
        #expect(result.contains("月"))
        #expect(result.contains("日"))
    }

    @Test func dateString_containsCorrectYear() {
        // 2020-07-01 12:00:00 UTC — noon UTC ensures the same calendar date
        // in any timezone from UTC-11 to UTC+14.
        let date = Date(timeIntervalSince1970: 1_593_604_800)
        let result = AppFormatters.dateString(date)
        #expect(result.contains("2020年"))
    }
}
