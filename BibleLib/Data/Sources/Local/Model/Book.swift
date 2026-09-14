//
//  Book.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct Book: Identifiable, Codable, Hashable {
    let id: String
    let bibleAbbr: String
    let abbreviation: String
    let name: String
    let nameLong: String
    var sortOrder: Int = 0
}
