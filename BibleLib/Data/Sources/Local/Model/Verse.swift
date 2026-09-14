//
//  Verse.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct VerseDisplay: Identifiable, Codable, Hashable {
    var id: String { verseId }
    var verseId: String
    let number: Int
    var text: String
    let chapterId: String
    let bookId: String
}

struct VerseChapterContent {
    let chapterId: String
    let bibleAbbr: String
    let bookId: String
    let verseCount: Int
    let verses: [VerseDisplay]
}
