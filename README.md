# VehicleManage

VehicleManage is an iOS fuel tracking app for recording vehicles, fuel-ups, fuel economy, fuel cost, and CPC fuel price data. The app is built with SwiftUI and SwiftData, and includes WidgetKit widgets for quick fuel price and vehicle summary views.

## Features

- Manage cars and motorcycles.
- Record fuel date, mileage, amount, fuel type, and cost.
- Calculate driven distance, fuel economy, and cost per kilometer.
- Fetch and store CPC fuel price data.
- **Cross-device sync** for Vehicle and FuelRecord data via CloudKit (same Apple ID, all devices).
- Share widget summary data between the app and widgets through App Group UserDefaults.
- Provide small and medium fuel price widgets.
- Provide small, medium, and large vehicle statistics widgets.

## Project Structure

```text
VehicleManage/                 Main iOS app
VehicleManage/Model/           SwiftData models
VehicleManage/View/            SwiftUI views
VehicleManage/DataManager/     Fuel price import and persistence logic
VehicleManage/Network/         Data access helpers
VehicleManage/Utilities/       Pure calculation, formatting, and sync helpers
VehicleManageWidget/           WidgetKit extension
VehicleManageTests/            Unit tests
VehicleManageUITests/          UI tests
VehicleManage.xcodeproj/       Xcode project and shared schemes
```

## Requirements

- Xcode 15 or later
- iOS 18.0 or later
- Apple Developer Program membership for device, TestFlight, App Store, App Groups, iCloud, and Xcode Cloud signing

## App Identifiers

| Target | Bundle ID |
| --- | --- |
| App | `ShaunChuang.VehicleManage` |
| Widget extension | `ShaunChuang.VehicleManage.VehicleManageWidget` |

The app and widget use this App Group:

```text
group.ShaunChuang.VehicleManage
```

Keep the App Group enabled for both the app target and the widget extension in the Apple Developer portal.

## CloudKit Sync Architecture

### Sync scope

| Model | Store | CloudKit |
| --- | --- | --- |
| `Vehicle` | SwiftData (CloudKit-backed) | ✅ Synced across devices |
| `FuelRecord` | SwiftData (CloudKit-backed) | ✅ Synced across devices |
| `CPCFuelPriceModel` | Local SQLite (`fuel_prices.sqlite` in App Group) | ❌ Not synced |

### iCloud container

The CloudKit container identifier is `iCloud.ShaunChuang.VehicleManage`.  
The container is configured with `cloudKitDatabase: .automatic`, which uses the first container in the entitlements and gracefully falls back to local-only storage when iCloud is unavailable.

### Required Apple Developer Portal setup

Before CloudKit sync will work on a real device or in TestFlight, complete the following in the Apple Developer portal and Xcode:

1. **iCloud Capability** — In the target's _Signing & Capabilities_ tab in Xcode, add _iCloud_ and check _CloudKit_.
2. **CloudKit container** — Create (or confirm) the container `iCloud.ShaunChuang.VehicleManage` in the portal under _Certificates, Identifiers & Profiles → Identifiers → (App ID) → iCloud Containers_.
3. **Regenerate provisioning profiles** after enabling the capability.
4. The entitlements files (`VehicleManage.entitlements` and `VehicleManageRelease.entitlements`) already include the required keys.

> **Note:** Without this portal setup the app still works; it stores Vehicle and FuelRecord locally without syncing.

### Widget data flow

The widget extension does **not** open a SwiftData container directly.  Instead:

1. The main app computes a `WidgetCache` snapshot (vehicle stats + current fuel prices) after every data update.
2. The snapshot is encoded as JSON and written to the App Group `UserDefaults` key `widgetCache`.
3. The widget providers (`VehicleStatsProvider`, `FuelConsumptionProvider`) read `WidgetDataCache.load()` from UserDefaults and build `FuelEntry` from that data.

The `WidgetDataCache.swift` file is compiled into **both** the main app target and the widget extension target.

## Legacy Data Migration

When a user upgrades from a version that stored all models in a single `vehiclemanage.sqlite` in the App Group:

1. On first launch after the upgrade, `LegacyDataMigration.migrateIfNeeded(...)` detects the old file.
2. It opens the old SQLite read-only via the SQLite3 C API and reads `ZVEHICLE` and `ZFUELRECORD` rows (CoreData/SwiftData Z-prefix table schema).
3. New `Vehicle` and `FuelRecord` objects are inserted into the CloudKit-synced SwiftData container.
4. Completion is marked in App Group `UserDefaults` (`cloudKitMigrationCompleted_v1`) so the migration runs only once.
5. The old `vehiclemanage.sqlite` is left on disk (not deleted) as a safety backup.
6. `CPCFuelPriceModel` data is **not** migrated; it is re-fetched from the CPC API automatically.

If the old SQLite is absent or the migration cannot read the expected table structure, the migration is silently skipped and the app continues with an empty synced store.

If CloudKit container setup is temporarily unavailable **before migration has completed**, the app may fall back to opening the legacy App Group store directly when `vehiclemanage.sqlite` exists, so pre-upgrade local data remains visible until CloudKit is available again. After `cloudKitMigrationCompleted_v1` has been set, the retained `vehiclemanage.sqlite` file is backup-only and should not be reopened for unrelated CloudKit setup failures, because doing so could surface stale pre-migration data.

## Versioning

Current project settings:

```text
MARKETING_VERSION = 3.0
CURRENT_PROJECT_VERSION = 3.0
```

For App Store Connect and TestFlight uploads, increment the build number before uploading another build for the same app version.

## Build

List schemes:

```sh
xcodebuild -list -project VehicleManage.xcodeproj
```

Build the app:

```sh
xcodebuild \
  -project VehicleManage.xcodeproj \
  -scheme VehicleManage \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  build
```

Archive the app:

```sh
xcodebuild \
  -project VehicleManage.xcodeproj \
  -scheme VehicleManage \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  archive \
  -archivePath /tmp/VehicleManage.xcarchive
```

## Test

Run unit and UI tests on a simulator:

```sh
xcodebuild \
  -project VehicleManage.xcodeproj \
  -scheme VehicleManage \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  test
```

If that simulator is unavailable, run `xcrun simctl list devices available` and choose an installed iOS simulator.

## Xcode Cloud

The shared app scheme is committed at:

```text
VehicleManage.xcodeproj/xcshareddata/xcschemes/VehicleManage.xcscheme
```

For the Xcode Cloud Archive action, use:

```text
Scheme: VehicleManage
Deployment Preparation: TestFlight and App Store
```

Do not archive the `VehicleManageWidgetExtension` scheme for App Store Connect distribution. The widget extension is embedded by the main app scheme.

## TestFlight

After a successful Xcode Cloud archive:

1. Open App Store Connect.
2. Select VehicleManage.
3. Open TestFlight.
4. Wait until the build finishes processing.
5. Add the build to an internal testing group.
6. Install the build on a device with the TestFlight app.

## Notes For Data Safety

- `Vehicle` and `FuelRecord` are now stored in a CloudKit-backed SwiftData container (default location managed by the OS, not in the App Group).
- `CPCFuelPriceModel` is stored in `fuel_prices.sqlite` inside the App Group container and is **not** synced to CloudKit.
- Avoid changing model property names, relationship rules, bundle IDs, or App Group identifiers without validating migration behavior on an installed production build.
- Before release, test upgrade from the latest App Store or TestFlight build to the new build with existing user data.
- The `@Attribute(.unique)` annotation was removed from `Vehicle.id` and `FuelRecord.id` because CloudKit does not support unique constraints. Data integrity is maintained by the app logic (e.g., the CPC import planner).
