//
//  ReaderTarget.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import Foundation

struct ReaderTarget: Hashable {
    var bibleAbbr: String
    var bookId: String = ""
    var chapterId: String = ""
    var verseId: String = ""
    var searchQuery: String = ""
}

struct NotesRequest: Identifiable, Hashable {
    let bibleAbbr: String
    let verseId: String
    let bookId: String
    let chapterId: String
    let title: String
    let verseText: String

    var id: String { "\(bibleAbbr)|\(verseId)" }
}

struct ScrollTarget: Equatable {
    let verseId: String
    var highlightQuery: String?
}

struct ChapterContext {
    let abbr: String
    let book: Book
    let chapter: Chapter
    let verses: [VerseDisplay]
}

extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
