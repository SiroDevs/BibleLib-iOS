//
//  Chapter.swift
//  BibleLib
//
//  Mirrors Android's ChapterEntity.
//

import Foundation

struct Chapter: Identifiable, Codable, Hashable {
    let id: String
    let bibleAbbr: String
    let bookId: String
    let number: String
    let reference: String
}
