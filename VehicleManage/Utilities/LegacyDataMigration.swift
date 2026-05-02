// LegacyDataMigration.swift
// VehicleManage
//
// One-time migration of Vehicle and FuelRecord data from the legacy
// App Group SQLite store (vehiclemanage.sqlite) to the new CloudKit-synced
// container.
//
// Strategy:
//   • Reads the old SQLite directly via SQLite3 (bypasses SwiftData schema
//     validation so no VersionedSchema boilerplate is needed).
//   • Inserts copies of each Vehicle and FuelRecord into the new synced
//     ModelContext, preserving the relationship via a local Z_PK → Vehicle map.
//   • Marks completion in App Group UserDefaults; subsequent launches skip it.
//   • All errors are caught and logged; migration failure does not crash the app.
//
// Assumptions about the legacy CoreData/SwiftData SQLite schema:
//   • Table ZVEHICLE with columns Z_PK, ZNAME, ZVEHICLETYPERAWVALUE,
//     ZDEFAULTFUELTYPERAWVALUE, ZISDEFAULT
//   • Table ZFUELRECORD with columns ZDATE, ZMILEAGE, ZFUELAMOUNT, ZCOST,
//     ZFUELTYPERAWVALUE, ZDRIVENDISTANCE, ZAVERAGEFUELCONSUMPTION,
//     ZCOSTPERKM, ZVEHICLE (FK → ZVEHICLE.Z_PK)
//   These follow CoreData's uppercase Z-prefix naming convention which
//   SwiftData inherits.

import Foundation
import SwiftData
import SQLite3

enum LegacyDataMigration {

    private static let migrationKey = "cloudKitMigrationCompleted_v1"
    private static let suiteName = "group.ShaunChuang.VehicleManage"

    static var isMigrationDone: Bool {
        UserDefaults(suiteName: suiteName)?.bool(forKey: migrationKey) ?? false
    }

    /// Checks if the legacy vehiclemanage.sqlite is present and, if so,
    /// copies its Vehicle + FuelRecord rows into `targetContext`.
    /// Must be called on the main actor.
    @MainActor
    static func migrateIfNeeded(targetContext: ModelContext, groupURL: URL) {
        guard !isMigrationDone else { return }

        let legacyURL = groupURL.appendingPathComponent("vehiclemanage.sqlite")
        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            markDone()
            return
        }

        do {
            let count = try migrateData(from: legacyURL, to: targetContext)
            markDone()
            print("舊資料遷移完成，共匯入 \(count) 筆車輛")
        } catch {
            // Non-fatal – the user can re-add data manually.
            print("舊資料遷移失敗（可忽略，下次啟動會重試）：\(error)")
        }
    }

    // MARK: - Internal

    private static func markDone() {
        UserDefaults(suiteName: suiteName)?.set(true, forKey: migrationKey)
    }

    /// Returns the number of vehicles successfully imported.
    @discardableResult
    private static func migrateData(from legacyURL: URL, to context: ModelContext) throws -> Int {
        var db: OpaquePointer?
        guard sqlite3_open_v2(legacyURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw MigrationError.cannotOpenDatabase
        }
        defer { sqlite3_close(db) }

        // Check that the expected tables exist before proceeding.
        guard tableExists("ZVEHICLE", in: db), tableExists("ZFUELRECORD", in: db) else {
            // Old store does not have the expected schema – treat as done.
            return 0
        }

        var vehicleMap: [Int32: Vehicle] = [:]
        try readVehicles(from: db, into: context, map: &vehicleMap)
        try readFuelRecords(from: db, into: context, vehicleMap: vehicleMap)
        try context.save()
        return vehicleMap.count
    }

    private static func tableExists(_ table: String, in db: OpaquePointer?) -> Bool {
        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, table, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_ROW
    }

    private static func readVehicles(
        from db: OpaquePointer?,
        into context: ModelContext,
        map: inout [Int32: Vehicle]
    ) throws {
        let sql = """
            SELECT Z_PK, ZNAME, ZVEHICLETYPERAWVALUE, ZDEFAULTFUELTYPERAWVALUE, ZISDEFAULT
            FROM ZVEHICLE
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let pk = sqlite3_column_int(stmt, 0)
            let name = text(stmt, 1) ?? "未命名"
            let typeRaw = text(stmt, 2) ?? VehicleType.car.rawValue
            let fuelRaw = text(stmt, 3) ?? FuelType.gas95.rawValue
            let isDefault = sqlite3_column_int(stmt, 4) != 0

            let vehicle = Vehicle(
                name: name,
                vehicleType: VehicleType(rawValue: typeRaw) ?? .car,
                defaultFuelType: FuelType(rawValue: fuelRaw) ?? .gas95,
                isDefault: isDefault
            )
            context.insert(vehicle)
            map[pk] = vehicle
        }
    }

    private static func readFuelRecords(
        from db: OpaquePointer?,
        into context: ModelContext,
        vehicleMap: [Int32: Vehicle]
    ) throws {
        let sql = """
            SELECT ZDATE, ZMILEAGE, ZFUELAMOUNT, ZCOST, ZFUELTYPERAWVALUE,
                   ZDRIVENDISTANCE, ZAVERAGEFUELCONSUMPTION, ZCOSTPERKM, ZVEHICLE
            FROM ZFUELRECORD
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            // CoreData stores dates as seconds since 2001-01-01 (NSDate reference date).
            let dateInterval = sqlite3_column_double(stmt, 0)
            let date = Date(timeIntervalSinceReferenceDate: dateInterval)
            let mileage = sqlite3_column_double(stmt, 1)
            let fuelAmount = sqlite3_column_double(stmt, 2)
            let cost = sqlite3_column_double(stmt, 3)
            let fuelTypeRaw = text(stmt, 4) ?? FuelType.gas95.rawValue
            let drivenDistance = sqlite3_column_double(stmt, 5)
            let avgFuelConsumption = sqlite3_column_double(stmt, 6)
            let costPerKm = sqlite3_column_double(stmt, 7)
            let vehiclePK = sqlite3_column_int(stmt, 8)

            let record = FuelRecord(
                date: date,
                mileage: mileage,
                fuelAmount: fuelAmount,
                cost: cost,
                fuelType: FuelType(rawValue: fuelTypeRaw) ?? .gas95,
                drivenDistance: drivenDistance,
                averageFuelConsumption: avgFuelConsumption,
                costPerKm: costPerKm,
                vehicle: vehicleMap[vehiclePK]
            )
            context.insert(record)
        }
    }

    // Convenience: read a TEXT column, returning nil if NULL.
    private static func text(_ stmt: OpaquePointer?, _ col: Int32) -> String? {
        guard sqlite3_column_type(stmt, col) != SQLITE_NULL,
              let cString = sqlite3_column_text(stmt, col)
        else { return nil }
        return String(cString: cString)
    }

    enum MigrationError: Error {
        case cannotOpenDatabase
    }
}
