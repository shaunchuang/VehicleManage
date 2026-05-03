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
//   • Table ZVEHICLE with columns Z_PK, ZID (UUID string), ZNAME,
//     ZVEHICLETYPERAWVALUE, ZDEFAULTFUELTYPERAWVALUE, ZISDEFAULT
//   • Table ZFUELRECORD with columns ZID (UUID string), ZDATE, ZMILEAGE,
//     ZFUELAMOUNT, ZCOST, ZFUELTYPERAWVALUE, ZDRIVENDISTANCE,
//     ZAVERAGEFUELCONSUMPTION, ZCOSTPERKM, ZVEHICLE (FK → ZVEHICLE.Z_PK)
//   These follow CoreData's uppercase Z-prefix naming convention which
//   SwiftData inherits.
//   ZID columns are read and preserved so that each logical record gets the
//   same UUID on every device, preventing CloudKit from treating the same
//   row as distinct records during multi-device first-run migration.

import Foundation
import SwiftData
import SQLite3

enum LegacyDataMigration {

    enum MigrationOutcome: Equatable {
        case skippedAlreadyCompleted
        case skippedMissingLegacyStore
        case migrated(vehicleCount: Int)
        case failed(message: String)
    }

    static let migrationKey = "cloudKitMigrationCompleted_v1"
    static let lastMigrationErrorKey = "cloudKitMigrationLastError_v1"
    static let suiteName = "group.ShaunChuang.VehicleManage"

    private static var migrationDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var isMigrationDone: Bool {
        migrationDefaults?.bool(forKey: migrationKey) ?? false
    }

    static var lastMigrationError: String? {
        migrationDefaults?.string(forKey: lastMigrationErrorKey)
    }

    /// Checks if the legacy vehiclemanage.sqlite is present and, if so,
    /// copies its Vehicle + FuelRecord rows into `targetContext`.
    /// Must be called on the main actor.
    @discardableResult
    @MainActor
    static func migrateIfNeeded(targetContext: ModelContext, groupURL: URL) -> MigrationOutcome {
        guard !isMigrationDone else { return .skippedAlreadyCompleted }

        let legacyURL = groupURL.appendingPathComponent("vehiclemanage.sqlite")
        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            markDone()
            return .skippedMissingLegacyStore
        }

        do {
            let count = try migrateData(from: legacyURL, to: targetContext)
            markDone()
            print("舊資料遷移完成，共匯入 \(count) 筆車輛")
            return .migrated(vehicleCount: count)
        } catch {
            let message = error.localizedDescription
            recordFailure(message)
            // Non-fatal – the user can re-add data manually.
            print("舊資料遷移失敗（可忽略，下次啟動會重試）：\(error)")
            return .failed(message: message)
        }
    }

    // MARK: - Internal

    private static func markDone() {
        migrationDefaults?.set(true, forKey: migrationKey)
        migrationDefaults?.removeObject(forKey: lastMigrationErrorKey)
    }

    private static func recordFailure(_ message: String) {
        migrationDefaults?.set(message, forKey: lastMigrationErrorKey)
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
        sqlite3_bind_text(stmt, 1, table, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        return sqlite3_step(stmt) == SQLITE_ROW
    }

    private static func readVehicles(
        from db: OpaquePointer?,
        into context: ModelContext,
        map: inout [Int32: Vehicle]
    ) throws {
        let sql = """
            SELECT Z_PK, ZID, ZNAME, ZVEHICLETYPERAWVALUE, ZDEFAULTFUELTYPERAWVALUE, ZISDEFAULT
            FROM ZVEHICLE
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let pk = sqlite3_column_int(stmt, 0)
            let vehicleID = text(stmt, 1).flatMap { UUID(uuidString: $0) } ?? UUID()
            let name = text(stmt, 2) ?? "未命名"
            let typeRaw = text(stmt, 3) ?? VehicleType.car.rawValue
            let fuelRaw = text(stmt, 4) ?? FuelType.gas95.rawValue
            let isDefault = sqlite3_column_int(stmt, 5) != 0

            let vehicle = Vehicle(
                name: name,
                vehicleType: VehicleType(rawValue: typeRaw) ?? .car,
                defaultFuelType: FuelType(rawValue: fuelRaw) ?? .gas95,
                isDefault: isDefault
            )
            vehicle.id = vehicleID
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
            SELECT ZID, ZDATE, ZMILEAGE, ZFUELAMOUNT, ZCOST, ZFUELTYPERAWVALUE,
                   ZDRIVENDISTANCE, ZAVERAGEFUELCONSUMPTION, ZCOSTPERKM, ZVEHICLE
            FROM ZFUELRECORD
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let recordID = text(stmt, 0).flatMap { UUID(uuidString: $0) } ?? UUID()
            // CoreData stores dates as seconds since 2001-01-01 (NSDate reference date).
            let dateInterval = sqlite3_column_double(stmt, 1)
            let date = Date(timeIntervalSinceReferenceDate: dateInterval)
            let mileage = sqlite3_column_double(stmt, 2)
            let fuelAmount = sqlite3_column_double(stmt, 3)
            let cost = sqlite3_column_double(stmt, 4)
            let fuelTypeRaw = text(stmt, 5) ?? FuelType.gas95.rawValue
            let drivenDistance = sqlite3_column_double(stmt, 6)
            let avgFuelConsumption = sqlite3_column_double(stmt, 7)
            let costPerKm = sqlite3_column_double(stmt, 8)
            let vehiclePK = sqlite3_column_int(stmt, 9)

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
            record.id = recordID
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
