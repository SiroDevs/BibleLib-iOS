//
//  MapCdToEntity.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct MapCdToEntity {
    static func mapToEntity(_ cd: CDBible) -> Bible {
        Bible(
            abbreviation: cd.abbreviation ?? "",
            name: cd.name ?? "",
            description: cd.bibleDescription ?? "",
            languageName: cd.languageName ?? "",
            scriptDirection: cd.scriptDirection ?? "LTR",
            sortOrder: Int(cd.sortOrder),
            isDownloaded: cd.isDownloaded,
            countryName: cd.countryName ?? "",
            downloadProgress: cd.downloadProgress,
            downloadFailed: cd.downloadFailed,
            path: cd.path ?? ""
        )
    }

    static func mapToEntity(_ cd: CDBook) -> Book {
        Book(
            id: cd.id ?? "",
            bibleAbbr: cd.bibleAbbr ?? "",
            abbreviation: cd.abbreviation ?? "",
            name: cd.name ?? "",
            nameLong: cd.nameLong ?? "",
            sortOrder: Int(cd.sortOrder)
        )
    }

    static func mapToEntity(_ cd: CDChapter) -> Chapter {
        Chapter(
            id: cd.id ?? "",
            bibleAbbr: cd.bibleAbbr ?? "",
            bookId: cd.bookId ?? "",
            number: cd.number ?? "",
            reference: cd.reference ?? ""
        )
    }

    static func mapToEntity(_ cd: CDVerse) -> VerseChapterContent {
        let verses: [VerseDisplay]
        if let json = cd.contentJson,
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([VerseDisplay].self, from: data) {
            verses = decoded
        } else {
            verses = []
        }
        return VerseChapterContent(
            chapterId: cd.chapterId ?? "",
            bibleAbbr: cd.bibleAbbr ?? "",
            bookId: cd.bookId ?? "",
            verseCount: Int(cd.verseCount),
            verses: verses
        )
    }

    static func mapToEntity(_ cd: CDBookmark) -> Bookmark {
        Bookmark(
            verseId: cd.verseId ?? "",
            bibleAbbr: cd.bibleAbbr ?? "",
            bookId: cd.bookId ?? "",
            chapterId: cd.chapterId ?? "",
            colorHex: cd.colorHex,
            createdAt: cd.createdAt ?? Date()
        )
    }

    static func mapToEntity(_ cd: CDNote) -> Note {
        Note(
            verseId: cd.verseId ?? "",
            bibleAbbr: cd.bibleAbbr ?? "",
            bookId: cd.bookId ?? "",
            chapterId: cd.chapterId ?? "",
            title: cd.title ?? "",
            verseText: cd.verseText ?? "",
            noteText: cd.noteText ?? "",
            updatedAt: cd.updatedAt ?? Date()
        )
    }

    static func mapToEntity(_ cd: CDHistory) -> HistoryEntry {
        HistoryEntry(
            id: cd.entryId ?? UUID().uuidString,
            bibleAbbr: cd.bibleAbbr ?? "",
            bibleName: cd.bibleName ?? "",
            bookId: cd.bookId ?? "",
            bookName: cd.bookName ?? "",
            chapterId: cd.chapterId ?? "",
            chapterRef: cd.chapterRef ?? "",
            verseNumber: cd.verseNumber > 0 ? Int(cd.verseNumber) : nil,
            dayKey: cd.dayKey ?? "",
            readAt: cd.readAt ?? Date()
        )
    }

    static func mapToEntity(_ cd: CDSearch) -> SearchEntry {
        SearchEntry(id: cd.searchId ?? UUID().uuidString, qry: cd.qry ?? "", queriedAt: cd.queriedAt ?? Date())
    }

    static func mapToEntity(_ cd: CDScriptureList) -> ScriptureList {
        ScriptureList(id: cd.listId, name: cd.name ?? "", createdAt: cd.createdAt ?? Date())
    }

    static func mapToEntity(_ cd: CDScriptureItem) -> ScriptureItem {
        ScriptureItem(
            id: cd.itemId,
            listId: cd.listId,
            bibleAbbr: cd.bibleAbbr ?? "",
            bibleName: cd.bibleName ?? "",
            bookId: cd.bookId ?? "",
            bookName: cd.bookName ?? "",
            bookAbbr: cd.bookAbbr ?? "",
            chapterId: cd.chapterId ?? "",
            chapterNumber: cd.chapterNumber ?? "",
            verseId: cd.verseId ?? "",
            verseNumber: Int(cd.verseNumber),
            reference: cd.reference ?? "",
            sortOrder: Int(cd.sortOrder),
            addedAt: cd.addedAt ?? Date()
        )
    }
}
