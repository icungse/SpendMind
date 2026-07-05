//
//  Date+Extensions.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import Foundation

extension Date {
    func isSameDay(as date: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: date)
    }

    func startOfDay(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
}
