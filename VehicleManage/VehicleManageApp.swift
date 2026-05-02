import SwiftData
import SwiftUI

@main
struct VehicleManageApp: App {
    let modelContainer: ModelContainer
    @AppStorage("lastFetchDate", store: UserDefaults(suiteName: "group.ShaunChuang.VehicleManage")) private var lastFetchDate: Double = 0

    init() {
        do {
            modelContainer = try Self.makeContainer()
        } catch {
            fatalError("無法建立模型容器：\(error)")
        }
    }

    // MARK: - Container factory

    private static func makeContainer() throws -> ModelContainer {
        let fullSchema = Schema([Vehicle.self, FuelRecord.self, CPCFuelPriceModel.self])

        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.ShaunChuang.VehicleManage"
        ) else {
            // Fallback: no App Group access – use in-memory defaults (should not
            // happen on a properly provisioned device).
            print("無法獲取 App Group 路徑，使用預設配置")
            return try ModelContainer(for: fullSchema)
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
            return container
        } catch {
            // CloudKit container creation failed (e.g. entitlements not yet
            // provisioned in the developer portal).  Fall back to a purely
            // local container so the app remains functional.
            print("CloudKit 容器建立失敗，改用本機儲存：\(error)")
            let fallbackSyncedConfig = ModelConfiguration(
                "synced",
                schema: Schema([Vehicle.self, FuelRecord.self]),
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: fullSchema,
                configurations: fallbackSyncedConfig, localConfig
            )
            // Do NOT run migration here: marking it done against the local-only
            // store would prevent it from running later when CloudKit is
            // properly provisioned, stranding the user's pre-upgrade data.
            return container
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

    var body: some Scene {
        WindowGroup {
            RootView(modelContainer: modelContainer, lastFetchDate: $lastFetchDate)
        }
    }
}
