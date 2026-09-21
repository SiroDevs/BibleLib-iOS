//
//  ParallelChapter.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import Foundation

struct ParallelChapter: Identifiable {
    let abbr: String
    let verses: [VerseDisplay]

    var id: String { abbr }

    func text(forVerse number: Int) -> String? {
        verses.first { $0.number == number }?.text
    }

    static func load(
        primary: String,
        chapterId: String,
        bibles: [Bible],
        prefs: PrefsRepo,
        repo: BibleRepoProtocol
    ) -> [ParallelChapter] {
        guard prefs.multiBibleReaderEnabled else { return [] }

        let downloaded = bibles
            .filter { $0.isDownloaded && $0.abbreviation != primary }
            .map(\.abbreviation)
        let chosen = prefs.secondaryBibles.filter(downloaded.contains)

        return (chosen.isEmpty ? downloaded : chosen).compactMap { abbr in
            repo.localVerses(abbr: abbr, chapterId: chapterId)
                .map { ParallelChapter(abbr: abbr, verses: $0.verses) }
        }
    }
}
