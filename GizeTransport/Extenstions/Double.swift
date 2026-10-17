//
//  Double.swift
//  UberSwiftUitutorial
//
//  Created by User on 12/22/22.
//

import Foundation
extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
    private var distanceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 1
        return formatter
    }
    func toCurrency() -> String {
        return currencyFormatter.string(for: self) ?? ""
    }
    func distanceInMilesString() -> String {
        return distanceFormatter.string(for: self / 1600) ?? ""
    }
}

