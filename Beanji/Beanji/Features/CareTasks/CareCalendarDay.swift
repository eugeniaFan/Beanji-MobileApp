//
//  CareCalendarDay.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 20.08.26.
//
//  Represents one day in the compact Care schedule.

import Foundation

struct CareCalendarDay: Identifiable, Equatable {
    let date: Date
    let isToday: Bool
    let hasWateringTask: Bool

    var id: Date {
        date
    }
}
