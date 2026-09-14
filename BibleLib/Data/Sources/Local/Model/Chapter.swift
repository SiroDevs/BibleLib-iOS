//
//  Chapter.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct Chapter: Identifiable, Codable, Hashable {
    let id: String
    let bibleAbbr: String
    let bookId: String
    let number: String
    let reference: String
}
