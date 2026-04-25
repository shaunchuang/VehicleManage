# VehicleManage

VehicleManage is an iOS fuel tracking app for recording vehicles, fuel-ups, fuel economy, fuel cost, and CPC fuel price data. The app is built with SwiftUI and SwiftData, and includes WidgetKit widgets for quick fuel price and vehicle summary views.

## Features

- Manage cars and motorcycles.
- Record fuel date, mileage, amount, fuel type, and cost.
- Calculate driven distance, fuel economy, and cost per kilometer.
- Fetch and store CPC fuel price data.
- Share data between the app and widgets through an App Group.
- Provide small and medium fuel price widgets.
- Provide small, medium, and large vehicle statistics widgets.

## Project Structure

```text
VehicleManage/                 Main iOS app
VehicleManage/Model/           SwiftData models
VehicleManage/View/            SwiftUI views
VehicleManage/DataManager/     Fuel price import and persistence logic
VehicleManage/Network/         Data access helpers
VehicleManage/Utilities/       Pure calculation and formatting helpers
VehicleManageWidget/           WidgetKit extension
VehicleManageTests/            Unit tests
VehicleManageUITests/          UI tests
VehicleManage.xcodeproj/       Xcode project and shared schemes
```

## Requirements

- Xcode 15 or later
- iOS 18.0 or later
- Apple Developer Program membership for device, TestFlight, App Store, App Groups, and Xcode Cloud signing

## App Identifiers

| Target | Bundle ID |
| --- | --- |
| App | `ShaunChuang.VehicleManage` |
| Widget extension | `ShaunChuang.VehicleManage.VehicleManageWidget` |

The app and widget use this App Group:

```text
group.ShaunChuang.VehicleManage
```

The SwiftData store is created in the App Group container at:

```text
vehiclemanage.sqlite
```

Keep the App Group enabled for both the app target and the widget extension in the Apple Developer portal.

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

- The app stores SwiftData models in the App Group container.
- The current schema includes `Vehicle`, `FuelRecord`, and `CPCFuelPriceModel`.
- Avoid changing model property names, relationship rules, bundle IDs, or App Group identifiers without validating migration behavior on an installed production build.
- Before release, test upgrade from the latest App Store or TestFlight build to the new build with existing user data.
