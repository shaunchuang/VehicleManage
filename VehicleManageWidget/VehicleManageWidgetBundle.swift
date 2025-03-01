import WidgetKit
import SwiftUI

@main
struct VehicleManageWidgetBundle: WidgetBundle {
    var body: some Widget {
        FuelConsumptionWidget()
        VehicleManageWidget()
    }
}
