//
//  BibleLookup.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

final class BibleLookup {
    private let bibleRepo: BibleRepoProtocol
    private var booksCache: [String: [String: Book]] = [:]
    private var chaptersCache: [String: [Chapter]] = [:]
    private var biblesCache: [String: Bible]?

    init(bibleRepo: BibleRepoProtocol) {
        self.bibleRepo = bibleRepo
    }

    func bible(_ abbr: String) -> Bible? {
        if biblesCache == nil {
            biblesCache = Dictionary(bibleRepo.localBibles().map { ($0.abbreviation, $0) }, uniquingKeysWith: { first, _ in first })
        }
        return biblesCache?[abbr]
    }

    func book(_ abbr: String, bookId: String) -> Book? {
        if booksCache[abbr] == nil {
            booksCache[abbr] = Dictionary(bibleRepo.localBooks(abbr: abbr).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }
        return booksCache[abbr]?[bookId]
    }

    func bookName(_ abbr: String, bookId: String) -> String {
        book(abbr, bookId: bookId)?.name ?? bookId
    }

    func chapter(_ abbr: String, bookId: String, chapterId: String) -> Chapter? {
        let key = "\(abbr)|\(bookId)"
        if chaptersCache[key] == nil {
            chaptersCache[key] = bibleRepo.localChapters(abbr: abbr, bookId: bookId)
        }
        return chaptersCache[key]?.first { $0.id == chapterId }
    }

    /// "Genesis 1:3" (falls back to what can be resolved).
    func reference(_ abbr: String, bookId: String, chapterId: String, verseNumber: Int?) -> String {
        var text = bookName(abbr, bookId: bookId)
        if let chapter = chapter(abbr, bookId: bookId, chapterId: chapterId) {
            text += " \(chapter.number)"
            if let verseNumber { text += ":\(verseNumber)" }
        }
        return text
    }

    func verse(_ abbr: String, chapterId: String, verseId: String) -> VerseDisplay? {
        bibleRepo.localVerses(abbr: abbr, chapterId: chapterId)?.verses.first { $0.verseId == verseId }
    }
}
