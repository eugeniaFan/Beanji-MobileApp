//
//  CareTaskFilter.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 07.08.26.
//

import Foundation

enum CareTaskFilter: String, CaseIterable, Identifiable {
    case today = "Heute"
    case tomorrow = "Morgen"
    case nextThreeDays = "3 Tage"
    case completed = "Erledigt"

    var id: Self { self }
}
