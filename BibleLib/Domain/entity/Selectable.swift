//
//  Selectable.swift
//  BibleLib
//
//  Carried over unchanged from SwahiLib's footprint.
//

import Foundation

struct Selectable<T>: Identifiable {
    let id = UUID()
    var data: T
    var isSelected: Bool
}
