import Foundation

enum FuelRecordMileageValidator {
    struct Bounds: Equatable {
        let minimumMileage: Double?
        let maximumMileage: Double?

        func contains(_ mileage: Double) -> Bool {
            if let minimumMileage, mileage < minimumMileage {
                return false
            }

            if let maximumMileage, mileage > maximumMileage {
                return false
            }

            return true
        }
    }

    static func bounds(
        for date: Date,
        in records: [FuelRecord],
        excluding excludedRecordID: UUID? = nil
    ) -> Bounds {
        let sortedRecords = records
            .filter { $0.id != excludedRecordID }
            .sorted {
                if $0.date == $1.date {
                    return $0.mileage < $1.mileage
                }
                return $0.date < $1.date
            }

        let nextIndex = sortedRecords.firstIndex(where: { $0.date > date }) ?? sortedRecords.endIndex
        let previousRecord = nextIndex > 0 ? sortedRecords[nextIndex - 1] : nil
        let nextRecord = nextIndex < sortedRecords.endIndex ? sortedRecords[nextIndex] : nil

        return Bounds(
            minimumMileage: previousRecord?.mileage,
            maximumMileage: nextRecord?.mileage
        )
    }

    static func errorMessage(
        for mileage: Double,
        on date: Date,
        in records: [FuelRecord],
        excluding excludedRecordID: UUID? = nil
    ) -> String? {
        let bounds = bounds(for: date, in: records, excluding: excludedRecordID)

        guard !bounds.contains(mileage) else {
            return nil
        }

        switch (bounds.minimumMileage, bounds.maximumMileage) {
        case let (.some(minimumMileage), .some(maximumMileage)):
            return "總里程數必須介於 \(String(format: "%.1f", minimumMileage)) 與 \(String(format: "%.1f", maximumMileage)) 公里之間"
        case let (.some(minimumMileage), nil):
            return "總里程數必須大於或等於 \(String(format: "%.1f", minimumMileage)) 公里"
        case let (nil, .some(maximumMileage)):
            return "總里程數必須小於或等於 \(String(format: "%.1f", maximumMileage)) 公里"
        case (nil, nil):
            return nil
        }
    }
}
