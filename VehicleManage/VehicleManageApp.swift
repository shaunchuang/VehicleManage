import CloudKit
import SwiftData
import SwiftUI

@main
struct VehicleManageApp: App {
    let modelContainer: ModelContainer
    let isCloudKitEnabled: Bool
    @AppStorage("lastFetchDate", store: UserDefaults(suiteName: AppConfiguration.appGroupIdentifier)) private var lastFetchDate: Double = 0

    init() {
        do {
            (modelContainer, isCloudKitEnabled) = try Self.makeContainer()
        } catch {
            fatalError("無法建立模型容器：\(error)")
        }
    }

    // MARK: - Container factory

    private static func makeContainer() throws -> (ModelContainer, Bool) {
        let fullSchema = Schema([Vehicle.self, FuelRecord.self, CPCFuelPriceModel.self])
        let legacyStoreFileName = "vehiclemanage.sqlite"

        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConfiguration.appGroupIdentifier
        ) else {
            // Fallback: no App Group access – use in-memory defaults (should not
            // happen on a properly provisioned device).
            print("無法獲取 App Group 路徑，使用預設配置")
            return (try ModelContainer(for: fullSchema), false)
        }

        // ── CloudKit-synced store: Vehicle + FuelRecord ──────────────────
        // cloudKitDatabase: .automatic uses the first iCloud container listed
        // in the app's entitlements and falls back to local-only storage when
        // iCloud is unavailable (e.g. signed-out or not yet provisioned).
        let syncedConfig = ModelConfiguration(
            "synced",
            schema: Schema([Vehicle.self, FuelRecord.self]),
            cloudKitDatabase: .automatic
        )

        // ── Local store: CPCFuelPriceModel (App Group, never synced) ─────
        // Stored in the App Group so the widget can still read it if needed,
        // but excluded from CloudKit because fuel prices are re-fetched from
        // the CPC API on every device independently.
        let localConfig = ModelConfiguration(
            "local",
            schema: Schema([CPCFuelPriceModel.self]),
            url: groupURL.appendingPathComponent("fuel_prices.sqlite"),
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(
                for: fullSchema,
                configurations: syncedConfig, localConfig
            )
            scheduleLegacyMigration(container: container, groupURL: groupURL)
            return (container, true)
        } catch {
            // The primary container setup can fail because CloudKit-backed
            // storage is unavailable or because one of the configured local
            // stores cannot be opened. Only reopen the original App Group
            // store before the one-time legacy migration has completed;
            // afterwards the retained SQLite file is backup-only and may be
            // stale.
            let nsError = error as NSError
            print("主要資料容器建立失敗 [domain=\(nsError.domain) code=\(nsError.code)]：\(error)")
            Self.logCloudKitAccountStatus()
            let legacyStoreURL = groupURL.appendingPathComponent(legacyStoreFileName)
            let shouldUseLegacyFallback =
                !LegacyDataMigration.isMigrationDone &&
                FileManager.default.fileExists(atPath: legacyStoreURL.path)

            if shouldUseLegacyFallback {
                do {
                    let legacyFallbackConfig = ModelConfiguration(
                        schema: fullSchema,
                        url: legacyStoreURL,
                        cloudKitDatabase: .none
                    )
                    return (try ModelContainer(
                        for: fullSchema,
                        configurations: legacyFallbackConfig
                    ), false)
                } catch {
                    let nsLegacyError = error as NSError
                    print("舊版資料庫開啟失敗 [domain=\(nsLegacyError.domain) code=\(nsLegacyError.code)]，改用新的本機儲存：\(error)")
                }
            }

            let fallbackSyncedConfig = ModelConfiguration(
                "synced",
                schema: Schema([Vehicle.self, FuelRecord.self]),
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: fullSchema,
                configurations: fallbackSyncedConfig, localConfig
            )
            // Do NOT run migration here: marking it done against the
            // local-only store would prevent it from running later when
            // CloudKit is properly provisioned, stranding the user's
            // pre-upgrade data.
            return (container, false)
        }
    }

    private static func scheduleLegacyMigration(container: ModelContainer, groupURL: URL) {
        Task { @MainActor in
            LegacyDataMigration.migrateIfNeeded(
                targetContext: container.mainContext,
                groupURL: groupURL
            )
        }
    }

    private static func logCloudKitAccountStatus() {
        CKContainer.default().accountStatus { status, error in
            let description: String
            switch status {
            case .available:              description = "available"
            case .noAccount:             description = "noAccount"
            case .restricted:            description = "restricted"
            case .couldNotDetermine:     description = "couldNotDetermine"
            case .temporarilyUnavailable: description = "temporarilyUnavailable"
            @unknown default:            description = "unknown(\(status.rawValue))"
            }
            if let error {
                let nsError = error as NSError
                print("CloudKit 帳號狀態：\(description)，錯誤 [domain=\(nsError.domain) code=\(nsError.code)]：\(error)")
            } else {
                print("CloudKit 帳號狀態：\(description)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(modelContainer: modelContainer, lastFetchDate: $lastFetchDate, isCloudKitEnabled: isCloudKitEnabled)
        }
    }
}
