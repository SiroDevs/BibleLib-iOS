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
}
