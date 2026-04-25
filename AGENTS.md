# AGENTS.md

This file gives coding agents project-specific guidance. Follow the repository code style and keep changes focused.

## Project Overview

VehicleManage is a SwiftUI iOS app with a WidgetKit extension. It uses SwiftData for persistence and stores the shared database in the App Group container.

Important identifiers:

```text
App bundle ID: ShaunChuang.VehicleManage
Widget bundle ID: ShaunChuang.VehicleManage.VehicleManageWidget
App Group: group.ShaunChuang.VehicleManage
Main scheme: VehicleManage
Widget scheme: VehicleManageWidgetExtension
```

## Build And Test

Prefer the main app scheme for app builds, tests, archives, and Xcode Cloud work:

```sh
xcodebuild -project VehicleManage.xcodeproj -scheme VehicleManage -configuration Debug -destination 'generic/platform=iOS' build
```

Archive with:

```sh
xcodebuild -project VehicleManage.xcodeproj -scheme VehicleManage -configuration Release -destination 'generic/platform=iOS' archive -archivePath /tmp/VehicleManage.xcarchive
```

Run tests with an installed simulator:

```sh
xcodebuild -project VehicleManage.xcodeproj -scheme VehicleManage -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' test
```

If the simulator name or OS is unavailable, check available devices:

```sh
xcrun simctl list devices available
```

## Xcode Cloud

The Archive action should use:

```text
Scheme: VehicleManage
Deployment Preparation: TestFlight and App Store
```

Do not use `VehicleManageWidgetExtension` as the Xcode Cloud archive scheme for App Store Connect distribution. The main app scheme embeds the widget extension.

## Data And Migration Safety

Treat SwiftData model changes as high risk. Before editing files in `VehicleManage/Model/`, inspect existing models and test upgrade behavior from a previously installed build when possible.

Be especially careful with:

- `VehicleManage/VehicleManageApp.swift`
- `VehicleManage/Model/Vehicle.swift`
- `VehicleManage/Model/FuelRecord.swift`
- `VehicleManage/Model/CPCFuelPriceModel.swift`
- Entitlement files under `VehicleManage/` and `VehicleManageWidget/`

Do not change the App Group identifier or bundle identifiers unless the task explicitly requires it.

## Coding Style

- Follow the existing SwiftUI and SwiftData patterns.
- Keep UI strings in Traditional Chinese unless the surrounding file uses English.
- Prefer pure helpers in `VehicleManage/Utilities/` for calculation logic that can be unit-tested.
- Keep comments concise and useful.
- Avoid broad refactors when fixing a narrow issue.

## Versioning

Current public app version and build number are both `3.0`:

```text
MARKETING_VERSION = 3.0
CURRENT_PROJECT_VERSION = 3.0
```

For App Store Connect uploads, make sure the app version matches the App Store Connect version record and the build number is acceptable for a new upload.

## Git Hygiene

- Do not commit user-specific Xcode files such as `xcuserdata`.
- Keep shared schemes under `VehicleManage.xcodeproj/xcshareddata/xcschemes/`.
- Do not commit DerivedData, archives, exported IPAs, signing certificates, provisioning profiles, or local environment files.
