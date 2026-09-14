//
//  Selectable.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct Selectable<T>: Identifiable {
    let id = UUID()
    var data: T
    var isSelected: Bool
}
