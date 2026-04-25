//
//  FuelTypeTests.swift
//  VehicleManageTests
//

import Testing
@testable import VehicleManage

struct FuelTypeTests {

    // MARK: - FuelType rawValues

    @Test func fuelType_gas92_rawValue() {
        #expect(FuelType.gas92.rawValue == "92無鉛")
    }

    @Test func fuelType_gas95_rawValue() {
        #expect(FuelType.gas95.rawValue == "95無鉛")
    }

    @Test func fuelType_gas98_rawValue() {
        #expect(FuelType.gas98.rawValue == "98無鉛")
    }

    @Test func fuelType_diesel_rawValue() {
        #expect(FuelType.diesel.rawValue == "超級柴油")
    }

    // MARK: - FuelType Identifiable

    @Test func fuelType_id_equalsRawValue() {
        for fuelType in FuelType.allCases {
            #expect(fuelType.id == fuelType.rawValue)
        }
    }

    // MARK: - FuelType CaseIterable

    @Test func fuelType_allCases_hasFourCases() {
        #expect(FuelType.allCases.count == 4)
    }

    // MARK: - FuelType RawRepresentable

    @Test func fuelType_initFromRawValue_valid() {
        #expect(FuelType(rawValue: "95無鉛") == .gas95)
    }

    @Test func fuelType_initFromRawValue_invalid_returnsNil() {
        #expect(FuelType(rawValue: "unknown") == nil)
    }

    @Test func fuelType_initFromRawValue_empty_returnsNil() {
        #expect(FuelType(rawValue: "") == nil)
    }

    // MARK: - VehicleType rawValues

    @Test func vehicleType_car_rawValue() {
        #expect(VehicleType.car.rawValue == "汽車")
    }

    @Test func vehicleType_motorcycle_rawValue() {
        #expect(VehicleType.motorcycle.rawValue == "機車")
    }

    // MARK: - VehicleType Identifiable

    @Test func vehicleType_id_equalsRawValue() {
        for vehicleType in VehicleType.allCases {
            #expect(vehicleType.id == vehicleType.rawValue)
        }
    }

    // MARK: - VehicleType CaseIterable

    @Test func vehicleType_allCases_hasTwoCases() {
        #expect(VehicleType.allCases.count == 2)
    }

    // MARK: - VehicleType RawRepresentable

    @Test func vehicleType_initFromRawValue_valid() {
        #expect(VehicleType(rawValue: "汽車") == .car)
        #expect(VehicleType(rawValue: "機車") == .motorcycle)
    }

    @Test func vehicleType_initFromRawValue_invalid_returnsNil() {
        #expect(VehicleType(rawValue: "unknown") == nil)
    }

    // MARK: - FuelType+CPCMapping: cpcProductName

    @Test func cpcProductName_gas98() {
        #expect(FuelType.gas98.cpcProductName == "無鉛汽油98")
    }

    @Test func cpcProductName_gas95() {
        #expect(FuelType.gas95.cpcProductName == "無鉛汽油95")
    }

    @Test func cpcProductName_gas92() {
        #expect(FuelType.gas92.cpcProductName == "無鉛汽油92")
    }

    @Test func cpcProductName_diesel() {
        #expect(FuelType.diesel.cpcProductName == "超級/高級柴油")
    }

    // MARK: - FuelType+CPCMapping: fromCPCProductName

    @Test func fromCPCProductName_gas98() {
        #expect(FuelType.fromCPCProductName("無鉛汽油98") == .gas98)
    }

    @Test func fromCPCProductName_gas95() {
        #expect(FuelType.fromCPCProductName("無鉛汽油95") == .gas95)
    }

    @Test func fromCPCProductName_gas92() {
        #expect(FuelType.fromCPCProductName("無鉛汽油92") == .gas92)
    }

    @Test func fromCPCProductName_diesel() {
        #expect(FuelType.fromCPCProductName("超級/高級柴油") == .diesel)
    }

    @Test func fromCPCProductName_unknownString_returnsNil() {
        #expect(FuelType.fromCPCProductName("unknown") == nil)
    }

    @Test func fromCPCProductName_emptyString_returnsNil() {
        #expect(FuelType.fromCPCProductName("") == nil)
    }

    // MARK: - FuelType+CPCMapping: allCPCProductNames

    @Test func allCPCProductNames_hasFourElements() {
        #expect(FuelType.allCPCProductNames.count == 4)
    }

    @Test func allCPCProductNames_containsAllMappedNames() {
        let names = FuelType.allCPCProductNames
        for fuelType in FuelType.allCases {
            #expect(names.contains(fuelType.cpcProductName))
        }
    }

    // MARK: - Round-trip: cpcProductName → fromCPCProductName

    @Test func cpcProductName_roundTrip() {
        for fuelType in FuelType.allCases {
            #expect(FuelType.fromCPCProductName(fuelType.cpcProductName) == fuelType)
        }
    }
}
