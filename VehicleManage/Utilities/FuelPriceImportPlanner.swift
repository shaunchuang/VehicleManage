import Foundation

struct FuelPriceSnapshot: Equatable {
    let effectiveDate: Date
    let price: Double
}

struct FuelPriceImportPlan: Equatable {
    let inserts: [FuelPriceSnapshot]
    let updates: [FuelPriceSnapshot]
    let duplicateDates: [Date]
}

enum FuelPriceImportPlanner {
    static func plan(
        apiSnapshots: [FuelPriceSnapshot],
        existingSnapshots: [FuelPriceSnapshot]
    ) -> FuelPriceImportPlan {
        let normalizedAPISnapshots = Dictionary(
            apiSnapshots.map { ($0.effectiveDate, $0) },
            uniquingKeysWith: { _, latest in latest }
        )
        let existingByDate = Dictionary(
            grouping: existingSnapshots,
            by: \.effectiveDate
        )

        var inserts: [FuelPriceSnapshot] = []
        var updates: [FuelPriceSnapshot] = []

        for snapshot in normalizedAPISnapshots.values.sorted(by: {
            $0.effectiveDate < $1.effectiveDate
        }) {
            if let existing = existingByDate[snapshot.effectiveDate]?.first {
                if existing.price != snapshot.price {
                    updates.append(snapshot)
                }
            } else {
                inserts.append(snapshot)
            }
        }

        let duplicateDates = existingByDate.compactMap { date, snapshots in
            snapshots.count > 1 ? date : nil
        }.sorted()

        return FuelPriceImportPlan(
            inserts: inserts,
            updates: updates,
            duplicateDates: duplicateDates
        )
    }
}
