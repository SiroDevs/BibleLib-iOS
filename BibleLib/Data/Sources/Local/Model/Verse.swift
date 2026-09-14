//
//  Verse.swift
//  BibleLib
//
//  VerseDisplay mirrors Android's VerseDisplay (core/common/entity/Basics.kt)
//  — a single verse already flattened out of the chapter's raw content tree.
//  VerseChapterContent mirrors VerseEntity: all of a chapter's verses cached
//  together as one row, keyed by (bibleAbbr, chapterId).
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
