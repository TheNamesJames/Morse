//
//  DateComponentsFormatterExt.swift
//  Morse
//
//  Created by James Wilkinson on 30/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import Foundation

extension DateComponentsFormatter {
    static func localizedString(from interval: TimeInterval, unitsStyle: DateComponentsFormatter.UnitsStyle, calendar: Calendar = .current, unitComponents: Set<Calendar.Component> = [.calendar, .year, .month, .day, .hour, .minute, .second]) -> String? {
        let d1 = Date()
        let d2 = Date(timeInterval: interval, since: d1)
        
        let dateComponents = Calendar.current.dateComponents(unitComponents, from: d1, to: d2)
        
        return localizedString(from: dateComponents, unitsStyle: unitsStyle)
    }
}
