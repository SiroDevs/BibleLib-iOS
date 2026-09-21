//
//  VerseSelectionModel.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import Foundation

final class VerseSelectionModel: ObservableObject {
    @Published private(set) var selectedIds: Set<String> = []
    @Published private(set) var bookmarks: [String: String] = [:]
    @Published private(set) var notedIds: Set<String> = []
    @Published var showColorPicker = false
    @Published var pendingColor: String?
    @Published var notesRequest: NotesRequest?

    private let annotations: AnnotationRepo
    private var context: ChapterContext?

    init(annotations: AnnotationRepo) {
        self.annotations = annotations
    }

    var isSelecting: Bool { !selectedIds.isEmpty }

    func load(_ context: ChapterContext) {
        self.context = context
        clear()
        reloadMarkers()
    }

    func reloadMarkers() {
        guard let context else { return }
        bookmarks = annotations.bookmarks(abbr: context.abbr, chapterId: context.chapter.id)
        notedIds = annotations.notedVerseIds(abbr: context.abbr, chapterId: context.chapter.id)
    }

    func toggle(_ verseId: String) {
        if selectedIds.contains(verseId) { selectedIds.remove(verseId) } else { selectedIds.insert(verseId) }
    }

    func clear() {
        selectedIds = []
        showColorPicker = false
        pendingColor = nil
    }

    func toggleBookmark(_ verse: VerseDisplay) {
        guard let context else { return }
        if bookmarks[verse.verseId] != nil {
            annotations.removeBookmarks(abbr: context.abbr, verseIds: [verse.verseId])
            bookmarks[verse.verseId] = nil
        } else {
            save(bookmarkFor: [verse.verseId], color: nil)
        }
    }

    func applyHighlight(_ hex: String) {
        pendingColor = hex
        showColorPicker = false
    }

    func confirmHighlight(withNote: Bool) {
        guard let color = pendingColor, let context else { return }
        let chosen = context.verses.filter { selectedIds.contains($0.verseId) }.sorted { $0.number < $1.number }
        save(bookmarkFor: chosen.map(\.verseId), color: color)
        if withNote, let first = chosen.first { notesRequest = request(for: first) }
        clear()
    }

    private func save(bookmarkFor ids: [String], color: String?) {
        guard let context else { return }
        annotations.setBookmarks(abbr: context.abbr, verseIds: ids, bookId: context.book.id, chapterId: context.chapter.id, colorHex: color)
        ids.forEach { bookmarks[$0] = color ?? "" }
    }

    func requestNote(for verse: VerseDisplay) {
        notesRequest = request(for: verse)
    }

    func requestNoteForSelection() {
        guard selectedIds.count == 1, let verse = context?.verses.first(where: { selectedIds.contains($0.verseId) }) else { return }
        requestNote(for: verse)
        clear()
    }

    private func request(for verse: VerseDisplay) -> NotesRequest {
        NotesRequest(
            bibleAbbr: context?.abbr ?? "",
            verseId: verse.verseId,
            bookId: context?.book.id ?? verse.bookId,
            chapterId: context?.chapter.id ?? verse.chapterId,
            title: "\(context?.book.name ?? verse.bookId) \(context?.chapter.number ?? ""):\(verse.number)",
            verseText: verse.text
        )
    }
}
