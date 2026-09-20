//
//  BookmarkNotesViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

struct BookmarkItem: Identifiable {
    let bookmark: Bookmark
    let reference: String
    let verseText: String
    let bibleAbbr: String
    var id: String { bookmark.id }
}

struct NoteItem: Identifiable {
    let note: Note
    let reference: String
    var id: String { note.id }
}

final class BookmarkNotesViewModel: ObservableObject {
    @Published private(set) var bookmarks: [BookmarkItem] = []
    @Published private(set) var notes: [NoteItem] = []
    @Published private(set) var isLoading = true

    private let annotationRepo: AnnotationRepo
    private let lookup: BibleLookup

    init(annotationRepo: AnnotationRepo, bibleRepo: BibleRepoProtocol) {
        self.annotationRepo = annotationRepo
        self.lookup = BibleLookup(bibleRepo: bibleRepo)
    }

    func load() {
        let savedBookmarks = annotationRepo.allBookmarks()
        let savedNotes = annotationRepo.allNotes()

        bookmarks = savedBookmarks.map { bookmark in
            let verse = lookup.verse(bookmark.bibleAbbr, chapterId: bookmark.chapterId, verseId: bookmark.verseId)
            return BookmarkItem(
                bookmark: bookmark,
                reference: lookup.reference(bookmark.bibleAbbr, bookId: bookmark.bookId, chapterId: bookmark.chapterId, verseNumber: verse?.number),
                verseText: verse?.text ?? "",
                bibleAbbr: bookmark.bibleAbbr
            )
        }
        notes = savedNotes.map { note in
            NoteItem(note: note, reference: note.title.isEmpty ? note.bookId : note.title)
        }
        isLoading = false
    }

    func deleteBookmarks(_ items: [BookmarkItem]) {
        annotationRepo.deleteBookmarks(items.map(\.bookmark))
        load()
    }

    func deleteNotes(_ items: [NoteItem]) {
        annotationRepo.deleteNotes(items.map(\.note))
        load()
    }

    func clearAll() {
        annotationRepo.clearAllBookmarksAndNotes()
        load()
    }
}
