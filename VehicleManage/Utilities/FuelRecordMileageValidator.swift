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
        let filteredRecords = records.filter { $0.id != excludedRecordID }
        let previousRecord = filteredRecords
            .filter { $0.date < date }
            .max {
                if $0.date == $1.date {
                    return $0.mileage < $1.mileage
                }
                return $0.date < $1.date
            }
        let nextRecord = filteredRecords
            .filter { $0.date > date }
            .min {
                if $0.date == $1.date {
                    return $0.mileage < $1.mileage
                }
                return $0.date < $1.date
            }

        return Bounds(
            minimumMileage: previousRecord?.mileage,
            maximumMileage: nextRecord?.mileage
        )
    }

    static func bounds(
        for mileage: Double,
        on date: Date,
        in records: [FuelRecord],
        excluding excludedRecordID: UUID? = nil
    ) -> Bounds {
        let filteredRecords = records.filter { $0.id != excludedRecordID }

        let previousDateRecord = filteredRecords
            .filter { $0.date < date }
            .max {
                if $0.date == $1.date {
                    return $0.mileage < $1.mileage
                }
                return $0.date < $1.date
            }
        let nextDateRecord = filteredRecords
            .filter { $0.date > date }
            .min {
                if $0.date == $1.date {
                    return $0.mileage < $1.mileage
                }
                return $0.date < $1.date
            }

        let sameDayRecords = filteredRecords
            .filter { $0.date == date }
            .sorted { $0.mileage < $1.mileage }

        let previousSameDayRecord = sameDayRecords.last(where: { $0.mileage <= mileage })
        let nextSameDayRecord = sameDayRecords.first(where: { $0.mileage >= mileage })

        return Bounds(
            minimumMileage: previousSameDayRecord?.mileage ?? previousDateRecord?.mileage,
            maximumMileage: nextSameDayRecord?.mileage ?? nextDateRecord?.mileage
        )
    }

    static func errorMessage(
        for mileage: Double,
        on date: Date,
        in records: [FuelRecord],
        excluding excludedRecordID: UUID? = nil
    ) -> String? {
        let bounds = bounds(for: mileage, on: date, in: records, excluding: excludedRecordID)

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
