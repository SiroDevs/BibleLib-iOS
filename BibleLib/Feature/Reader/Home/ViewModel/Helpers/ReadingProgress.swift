//
//  ReadingProgress.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import Foundation

struct ReadingProgress {
    let prefs: PrefsRepo
    let tracking: TrackingRepo
    let queue: ScriptureQueueRepo

    func chapterLoaded(_ context: ChapterContext, bibleName: String) {
        prefs.lastBibleAbbr = context.abbr
        prefs.lastBookId = context.book.id
        prefs.lastChapterId = context.chapter.id
        prefs.lastBible = bibleName
        queue.syncActiveByChapter(bibleAbbr: context.abbr, chapterId: context.chapter.id)
        record(context, bibleName: bibleName, verseNumber: context.verses.first?.number ?? 1)
    }

    func verseViewed(_ verse: VerseDisplay, in context: ChapterContext, bibleName: String) {
        prefs.lastVerseId = verse.verseId
        record(context, bibleName: bibleName, verseNumber: verse.number)
    }

    private func record(_ context: ChapterContext, bibleName: String, verseNumber: Int) {
        tracking.recordReading(
            HistoryEntry(
                bibleAbbr: context.abbr,
                bibleName: bibleName,
                bookId: context.book.id,
                bookName: context.book.name,
                chapterId: context.chapter.id,
                chapterRef: context.chapter.reference,
                verseNumber: verseNumber
            )
        )
    }
}
