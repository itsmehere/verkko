//
//  Date+Ext.swift
//  Verkko
//
//  Created by Justin Wong on 8/21/23.
//

import Foundation

extension Date {
    func isSameDay(as date: Date) -> Bool {
        let calendar = Calendar.current

        let components1 = calendar.dateComponents([.year, .month, .day], from: date)
        let components2 = calendar.dateComponents([.year, .month, .day], from: self)

        return components1.year == components2.year &&
               components1.month == components2.month &&
               components1.day == components2.day
    }
    
    func getDayComponent() -> Int? {
        return Calendar.current.component(.day, from: self)
    }
    
    func getWeekComponent() -> Int? {
        return Calendar.current.component(.weekOfYear, from: self)
    }
    
    func getMonthComponent() -> Int? {
        return Calendar.current.component(.month, from: self)
    }
    
    func getYearComponent() -> Int? {
        return Calendar.current.component(.year, from: self)
    }
}
