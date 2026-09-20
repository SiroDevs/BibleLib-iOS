//
//  GroupingMode.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
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
