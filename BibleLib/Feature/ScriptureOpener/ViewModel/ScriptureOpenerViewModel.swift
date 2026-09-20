//
//  ScriptureOpenerViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

enum ExpandedField {
    case none, book, chapter, verse
}

struct ScriptureSearchRow: Identifiable {
    let id = UUID()
    var locked = false
    var expanded: ExpandedField = .book
    var books: [Book] = []
    var selectedBook: Book?
    var chapters: [Chapter] = []
    var selectedChapter: Chapter?
    var verses: [VerseDisplay] = []
    var selectedVerseNumber: Int?

    var bookLabel: String { selectedBook?.name ?? "" }
    var chapterLabel: String { selectedChapter?.number ?? "" }
    var verseLabel: String { selectedVerseNumber.map(String.init) ?? "" }
    var canExpandChapter: Bool { selectedBook != nil }
    var canExpandVerse: Bool { selectedChapter != nil }
    var isComplete: Bool { selectedBook != nil && selectedChapter != nil && selectedVerseNumber != nil }
    var selectedVerseId: String? { verses.first { $0.number == selectedVerseNumber }?.verseId }

    var reference: String {
        guard let book = selectedBook, let chapter = selectedChapter, let verse = selectedVerseNumber else { return "" }
        return "\(book.name) \(chapter.number):\(verse)"
    }
}

final class ScriptureOpenerViewModel: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var error: String?
    @Published private(set) var bibleAbbr = ""
    @Published private(set) var bibleName = ""
    @Published var rows: [ScriptureSearchRow] = []
    @Published var readerTarget: ReaderTarget?
    @Published var closeRequested = false

    private let bibleRepo: BibleRepoProtocol
    private let scriptureRepo: ScriptureRepo
    private let queueRepo: ScriptureQueueRepo
    private let prefsRepo: PrefsRepo

    init(bibleRepo: BibleRepoProtocol, scriptureRepo: ScriptureRepo, queueRepo: ScriptureQueueRepo, prefsRepo: PrefsRepo) {
        self.bibleRepo = bibleRepo
        self.scriptureRepo = scriptureRepo
        self.queueRepo = queueRepo
        self.prefsRepo = prefsRepo
    }

    func initialize(bibleAbbr: String, bibleName: String) {
        guard !(self.bibleAbbr == bibleAbbr && !rows.isEmpty) else { return }
        self.bibleAbbr = bibleAbbr
        self.bibleName = bibleName
        error = nil

        let books = bibleRepo.localBooks(abbr: bibleAbbr)
        guard !books.isEmpty else {
            isLoading = false
            error = "No books found for this Bible."
            return
        }
        rows = [ScriptureSearchRow(books: books)]
        isLoading = false
    }

    func toggleField(rowId: UUID, field: ExpandedField) {
        update(rowId) { row in
            guard !row.locked else { return }
            let allowed: Bool
            switch field {
            case .book, .none: allowed = true
            case .chapter: allowed = row.canExpandChapter
            case .verse: allowed = row.canExpandVerse
            }
            guard allowed else { return }
            row.expanded = row.expanded == field ? .none : field
        }
    }

    func selectBook(rowId: UUID, book: Book) {
        let chapters = bibleRepo.localChapters(abbr: bibleAbbr, bookId: book.id)
        update(rowId) { row in
            row.selectedBook = book
            row.selectedChapter = nil
            row.selectedVerseNumber = nil
            row.verses = []
            row.chapters = chapters
            row.expanded = .chapter
        }
    }

    func selectChapter(rowId: UUID, chapter: Chapter) {
        let verses = bibleRepo.localVerses(abbr: bibleAbbr, chapterId: chapter.id)?.verses ?? []
        update(rowId) { row in
            row.selectedChapter = chapter
            row.selectedVerseNumber = nil
            row.verses = verses
            row.expanded = .verse
        }
    }

    func selectVerse(rowId: UUID, number: Int) {
        update(rowId) { row in
            row.selectedVerseNumber = number
            row.expanded = .none
        }
    }

    func openScripture(rowId: UUID) {
        guard let row = rows.first(where: { $0.id == rowId }), let target = target(for: row) else { return }
        prefsRepo.lastVerseId = target.verseId
        readerTarget = target
    }

    func addToQueue(rowId: UUID) {
        guard let row = rows.first(where: { $0.id == rowId }), row.isComplete else { return }
        update(rowId) { $0.locked = true; $0.expanded = .none }
        rows.append(ScriptureSearchRow(books: row.books))
    }

    func addToQueueAndClose(rowId: UUID) {
        guard let row = rows.first(where: { $0.id == rowId }), row.isComplete else { return }
        _ = persistQueue(including: rowId)
        closeRequested = true
    }

    func addToQueueAndFinish(rowId: UUID) {
        guard let row = rows.first(where: { $0.id == rowId }), row.isComplete else { return }
        guard let first = persistQueue(including: rowId).first else { return }
        prefsRepo.lastVerseId = first.verseId
        readerTarget = ReaderTarget(
            bibleAbbr: first.bibleAbbr,
            bookId: first.bookId,
            chapterId: first.chapterId,
            verseId: first.verseId
        )
    }

    func consumeReaderTarget() { readerTarget = nil }
    func consumeClose() { closeRequested = false }

    private func persistQueue(including rowId: UUID) -> [ScriptureItem] {
        let completed = rows.filter { $0.locked || $0.id == rowId }
        let items = completed.enumerated().compactMap { index, row in makeItem(row, order: index) }
        guard !items.isEmpty else { return [] }

        let listId = scriptureRepo.saveList(items: items)
        let saved = scriptureRepo.items(listId: listId)
        let name = scriptureRepo.list(id: listId)?.name ?? saved.first?.reference ?? ""
        queueRepo.open(listId: listId, listName: name, items: saved)
        return saved
    }

    private func makeItem(_ row: ScriptureSearchRow, order: Int) -> ScriptureItem? {
        guard let book = row.selectedBook,
              let chapter = row.selectedChapter,
              let verseNumber = row.selectedVerseNumber,
              let verseId = row.selectedVerseId else { return nil }
        return ScriptureItem(
            bibleAbbr: bibleAbbr,
            bibleName: bibleName,
            bookId: book.id,
            bookName: book.name,
            bookAbbr: book.abbreviation,
            chapterId: chapter.id,
            chapterNumber: chapter.number,
            verseId: verseId,
            verseNumber: verseNumber,
            reference: "\(book.name) \(chapter.number):\(verseNumber)",
            sortOrder: order
        )
    }

    private func target(for row: ScriptureSearchRow) -> ReaderTarget? {
        guard let book = row.selectedBook, let chapter = row.selectedChapter, let verseId = row.selectedVerseId else { return nil }
        return ReaderTarget(bibleAbbr: bibleAbbr, bookId: book.id, chapterId: chapter.id, verseId: verseId)
    }

    private func update(_ rowId: UUID, _ transform: (inout ScriptureSearchRow) -> Void) {
        guard let index = rows.firstIndex(where: { $0.id == rowId }) else { return }
        transform(&rows[index])
    }
}
