//
//  AnnotationRepo.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

final class AnnotationRepo {
    private let data: UserDataManager

    init(data: UserDataManager) {
        self.data = data
    }

    func bookmarks(abbr: String, chapterId: String) -> [String: String] {
        data.bookmarks(abbr: abbr, chapterId: chapterId)
    }

    func notedVerseIds(abbr: String, chapterId: String) -> Set<String> {
        data.notedVerseIds(abbr: abbr, chapterId: chapterId)
    }

    func setBookmarks(abbr: String, verseIds: [String], bookId: String, chapterId: String, colorHex: String?) {
        data.setBookmarks(abbr: abbr, verseIds: verseIds, bookId: bookId, chapterId: chapterId, colorHex: colorHex)
    }

    func removeBookmarks(abbr: String, verseIds: [String]) {
        data.removeBookmarks(abbr: abbr, verseIds: verseIds)
    }

    func note(abbr: String, verseId: String) -> Note? {
        data.note(abbr: abbr, verseId: verseId)
    }

    func saveNote(_ note: Note) {
        data.saveNote(note)
    }

    func deleteNote(abbr: String, verseId: String) {
        data.deleteNote(abbr: abbr, verseId: verseId)
    }

    func allBookmarks() -> [Bookmark] { data.allBookmarks() }

    func allNotes() -> [Note] { data.allNotes() }

    func deleteBookmarks(_ items: [Bookmark]) {
        for (abbr, group) in Dictionary(grouping: items, by: \.bibleAbbr) {
            data.removeBookmarks(abbr: abbr, verseIds: group.map(\.verseId))
        }
    }

    func deleteNotes(_ items: [Note]) {
        items.forEach { data.deleteNote(abbr: $0.bibleAbbr, verseId: $0.verseId) }
    }

    func clearAllBookmarksAndNotes() {
        data.deleteAllBookmarks()
        data.deleteAllNotes()
    }
}
