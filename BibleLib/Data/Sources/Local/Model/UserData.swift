//
//  UserData.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//


import Foundation

struct Bookmark: Identifiable, Hashable {
    var id: String { "\(bibleAbbr)|\(verseId)" }
    let verseId: String
    let bibleAbbr: String
    let bookId: String
    let chapterId: String
    var colorHex: String?
    var createdAt: Date = Date()
}

struct Note: Identifiable, Hashable {
    var id: String { "\(bibleAbbr)|\(verseId)" }
    let verseId: String
    let bibleAbbr: String
    let bookId: String
    let chapterId: String
    var title: String
    var verseText: String
    var noteText: String
    var updatedAt: Date = Date()
}

struct HistoryEntry: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let bibleAbbr: String
    var bibleName: String = ""
    let bookId: String
    var bookName: String
    let chapterId: String
    var chapterRef: String
    var verseNumber: Int?
    var dayKey: String = ""
    var readAt: Date = Date()
}

struct SearchEntry: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let qry: String
    var queriedAt: Date = Date()
}

struct ScriptureList: Identifiable, Hashable {
    let id: Int64
    var name: String
    var createdAt: Date = Date()
}

struct ScriptureItem: Identifiable, Hashable {
    var id: Int64 = 0
    var listId: Int64 = 0
    let bibleAbbr: String
    let bibleName: String
    let bookId: String
    let bookName: String
    let bookAbbr: String
    let chapterId: String
    let chapterNumber: String
    let verseId: String
    let verseNumber: Int
    let reference: String
    var sortOrder: Int = 0
    var addedAt: Date = Date()
}
