//
//  GroupingMode.swift
//  BibleLib
//
//  Port of Android's GroupingMode (feature/selection/.../utils/GroupingMode.kt).
//

import Foundation

enum GroupingMode: CaseIterable, Identifiable {
    case regions
    case countries
    case languages
    case ungrouped

    static let `default`: GroupingMode = .regions

    var id: Self { self }

    var label: String {
        switch self {
        case .regions: return "Regions"
        case .countries: return "Countries"
        case .languages: return "Languages"
        case .ungrouped: return "None"
        }
    }
}
