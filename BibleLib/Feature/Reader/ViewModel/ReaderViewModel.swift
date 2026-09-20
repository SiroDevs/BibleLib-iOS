//
//  ReaderViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation
import Combine

struct ScrollTarget: Equatable {
    let verseId: String
    var highlightQuery: String?
}

extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}

final class ReaderViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var error: String?

    @Published var savedBibles: [Bible] = []
    @Published var activeBible = ""
    @Published var activeBibleAbbr = ""

    @Published var books: [Book] = []
    @Published var activeBook: Book?
    @Published var chapters: [Chapter] = []
    @Published var activeChapter: Chapter?

    @Published var verses: [VerseDisplay] = []
    @Published var parallelVerses: [String: [VerseDisplay]] = [:]
    @Published var parallelOrder: [String] = []

    @Published var fontSize: Double = ReaderFontSize.standard
    @Published var fontFamilyId = "default"
    @Published var readerBackgroundId = "default"
    @Published var multiBibleReaderEnabled = true

    @Published var restoreVerseId: String?
    @Published var highlightQuery: String?

    @Published var bookmarks: [String: String] = [:]
    @Published var notedVerseIds: Set<String> = []

    @Published var selectedVerseIds: Set<String> = []
    @Published var showColorPicker = false
    @Published var pendingHighlightColor: String?
    @Published var notesRequest: NotesRequest?

    @Published var queueItems: [ScriptureItem] = []
    @Published var queueActiveItemId: Int64?

    var isSelectionMode: Bool { !selectedVerseIds.isEmpty }
    var isScriptureModeActive: Bool { queueItems.count > 1 }

    var activeBibleLanguage: String? {
        savedBibles.first { $0.abbreviation == activeBibleAbbr }?.languageName
    }

    private var activeChapterIndex: Int? {
        guard let active = activeChapter else { return nil }
        return chapters.firstIndex { $0.id == active.id }
    }

    var hasPrevChapter: Bool { (activeChapterIndex ?? 0) > 0 }

    var hasNextChapter: Bool {
        guard let index = activeChapterIndex else { return false }
        return index < chapters.count - 1
    }

    var prevChapterLabel: String {
        guard let index = activeChapterIndex, index > 0 else { return "Previous chapter" }
        return chapters[index - 1].reference
    }

    var nextChapterLabel: String {
        guard let index = activeChapterIndex, index < chapters.count - 1 else { return "Next chapter" }
        return chapters[index + 1].reference
    }

    private let bibleRepo: BibleRepoProtocol
    private let prefsRepo: PrefsRepo
    private let annotationRepo: AnnotationRepo
    private let trackingRepo: TrackingRepo
    private let queueRepo: ScriptureQueueRepo

    private var isFirstLoad = false
    private var cancellables = Set<AnyCancellable>()

    init(
        bibleRepo: BibleRepoProtocol,
        prefsRepo: PrefsRepo,
        annotationRepo: AnnotationRepo,
        trackingRepo: TrackingRepo,
        queueRepo: ScriptureQueueRepo
    ) {
        self.bibleRepo = bibleRepo
        self.prefsRepo = prefsRepo
        self.annotationRepo = annotationRepo
        self.trackingRepo = trackingRepo
        self.queueRepo = queueRepo

        Publishers.CombineLatest(queueRepo.$items, queueRepo.$activeItemId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items, activeId in
                self?.queueItems = items
                self?.queueActiveItemId = activeId
            }
            .store(in: &cancellables)
    }

    @MainActor
    func initialize(target: ReaderTarget? = nil) async {
        error = nil
        let bibles = bibleRepo.localBibles()
        guard !bibles.isEmpty else {
            isLoading = false
            error = "No Bibles downloaded yet."
            return
        }

        var abbr = target?.bibleAbbr.nonEmpty
            ?? prefsRepo.lastBibleAbbr.nonEmpty
            ?? prefsRepo.primaryBibleAbbr
            ?? ""
        if !bibles.contains(where: { $0.abbreviation == abbr }) {
            abbr = bibles[0].abbreviation
        }

        isFirstLoad = true
        savedBibles = bibles
        activeBibleAbbr = abbr
        activeBible = bibles.first { $0.abbreviation == abbr }?.name ?? prefsRepo.lastBible
        fontSize = prefsRepo.fontSize
        fontFamilyId = prefsRepo.readerFontFamily
        readerBackgroundId = prefsRepo.readerBackground
        multiBibleReaderEnabled = prefsRepo.multiBibleReaderEnabled

        let scrollTarget = target?.verseId.nonEmpty.map {
            ScrollTarget(verseId: $0, highlightQuery: target?.searchQuery.nonEmpty)
        }
        await loadBooks(abbr: abbr, bookId: target?.bookId ?? "", chapterId: target?.chapterId ?? "", scrollTarget: scrollTarget)
    }

    @MainActor
    func refresh() async {
        guard !activeBibleAbbr.isEmpty else { return }
        savedBibles = bibleRepo.localBibles()

        let desired = prefsRepo.lastBibleAbbr.nonEmpty ?? prefsRepo.primaryBibleAbbr ?? activeBibleAbbr
        if desired != activeBibleAbbr || !savedBibles.contains(where: { $0.abbreviation == activeBibleAbbr }) {
            await initialize()
            return
        }
        fontSize = prefsRepo.fontSize
        fontFamilyId = prefsRepo.readerFontFamily
        readerBackgroundId = prefsRepo.readerBackground
        multiBibleReaderEnabled = prefsRepo.multiBibleReaderEnabled

        guard let chapter = activeChapter else { return }
        let parallel = loadParallel(primaryAbbr: activeBibleAbbr, chapterId: chapter.id)
        parallelVerses = parallel.verses
        parallelOrder = parallel.order
        bookmarks = annotationRepo.bookmarks(abbr: activeBibleAbbr, chapterId: chapter.id)
        notedVerseIds = annotationRepo.notedVerseIds(abbr: activeBibleAbbr, chapterId: chapter.id)
    }

    @MainActor
    private func loadBooks(abbr: String, bookId: String, chapterId: String, scrollTarget: ScrollTarget? = nil) async {
        let loaded = bibleRepo.localBooks(abbr: abbr)
        guard !loaded.isEmpty else {
            isLoading = false
            error = "Bible data not available. Please wait for the download to complete."
            return
        }

        let resolvedBookId = bookId.nonEmpty ?? prefsRepo.lastBookId
        let resolvedChapterId = chapterId.nonEmpty ?? prefsRepo.lastChapterId
        let targetBook = loaded.first { $0.id == resolvedBookId } ?? loaded[0]

        books = loaded
        activeBook = targetBook
        await loadChapters(abbr: abbr, book: targetBook, chapterId: resolvedChapterId, scrollTarget: scrollTarget)
    }

    @MainActor
    private func loadChapters(
        abbr: String,
        book: Book,
        chapterId: String,
        forceScrollToFirstVerse: Bool = false,
        scrollTarget: ScrollTarget? = nil
    ) async {
        let loaded = bibleRepo.localChapters(abbr: abbr, bookId: book.id)
        guard !loaded.isEmpty else {
            isLoading = false
            error = "No chapters found for \(book.name)"
            return
        }

        let target = loaded.first { $0.id == chapterId } ?? loaded[0]
        chapters = loaded
        activeChapter = target
        await loadVerses(abbr: abbr, chapter: target, scrollTarget: scrollTarget, forceScrollToFirstVerse: forceScrollToFirstVerse)
    }

    @MainActor
    func loadVerses(
        abbr: String,
        chapter: Chapter,
        scrollTarget: ScrollTarget? = nil,
        forceScrollToFirstVerse: Bool = false
    ) async {
        if verses.isEmpty { isLoading = true }
        error = nil

        guard let content = bibleRepo.localVerses(abbr: abbr, chapterId: chapter.id) else {
            isLoading = false
            error = "Verses not cached. Please ensure download is complete."
            return
        }

        let loadedVerses = content.verses
        let parallel = loadParallel(primaryAbbr: abbr, chapterId: chapter.id)
        let resolved = resolveScrollTarget(explicit: scrollTarget, forceFirst: forceScrollToFirstVerse, verses: loadedVerses)

        verses = loadedVerses
        parallelVerses = parallel.verses
        parallelOrder = parallel.order
        activeChapter = chapter
        activeBibleAbbr = abbr
        bookmarks = annotationRepo.bookmarks(abbr: abbr, chapterId: chapter.id)
        notedVerseIds = annotationRepo.notedVerseIds(abbr: abbr, chapterId: chapter.id)
        selectedVerseIds = []
        showColorPicker = false
        pendingHighlightColor = nil
        multiBibleReaderEnabled = prefsRepo.multiBibleReaderEnabled
        restoreVerseId = resolved?.verseId
        highlightQuery = resolved?.highlightQuery
        isLoading = false

        recordVersesLoaded(abbr: abbr, chapter: chapter, verses: loadedVerses)
    }

    private func loadParallel(primaryAbbr: String, chapterId: String) -> (verses: [String: [VerseDisplay]], order: [String]) {
        guard prefsRepo.multiBibleReaderEnabled else { return ([:], []) }

        let downloaded = Set(savedBibles.filter(\.isDownloaded).map(\.abbreviation))
        var ordered = prefsRepo.secondaryBibles.filter { $0 != primaryAbbr && downloaded.contains($0) }
        if ordered.isEmpty {
            ordered = savedBibles.filter { $0.abbreviation != primaryAbbr && $0.isDownloaded }.map(\.abbreviation)
        }

        var result: [String: [VerseDisplay]] = [:]
        var order: [String] = []
        for abbr in ordered {
            if let content = bibleRepo.localVerses(abbr: abbr, chapterId: chapterId) {
                result[abbr] = content.verses
                order.append(abbr)
            }
        }
        return (result, order)
    }

    func setMultiBibleReaderEnabled(_ enabled: Bool) {
        prefsRepo.multiBibleReaderEnabled = enabled
        multiBibleReaderEnabled = enabled
        guard let chapter = activeChapter else { return }
        let parallel = loadParallel(primaryAbbr: activeBibleAbbr, chapterId: chapter.id)
        parallelVerses = parallel.verses
        parallelOrder = parallel.order
    }

    private func resolveScrollTarget(explicit: ScrollTarget?, forceFirst: Bool, verses: [VerseDisplay]) -> ScrollTarget? {
        let resolved: ScrollTarget?
        if let explicit {
            resolved = explicit
        } else if forceFirst {
            resolved = verses.first.map { ScrollTarget(verseId: $0.verseId) }
        } else if isFirstLoad {
            resolved = prefsRepo.lastVerseId.nonEmpty.map { ScrollTarget(verseId: $0) }
        } else {
            resolved = nil
        }
        isFirstLoad = false
        return resolved
    }

    private func recordVersesLoaded(abbr: String, chapter: Chapter, verses: [VerseDisplay]) {
        prefsRepo.lastBibleAbbr = abbr
        prefsRepo.lastBookId = chapter.bookId
        prefsRepo.lastChapterId = chapter.id
        if !activeBible.isEmpty { prefsRepo.lastBible = activeBible }
        queueRepo.syncActiveByChapter(bibleAbbr: abbr, chapterId: chapter.id)

        guard let book = activeBook else { return }
        trackingRepo.recordReading(
            HistoryEntry(
                bibleAbbr: abbr,
                bibleName: activeBible,
                bookId: book.id,
                bookName: book.name,
                chapterId: chapter.id,
                chapterRef: chapter.reference,
                verseNumber: verses.first?.number ?? 1
            )
        )
    }

    func onVerseScrollPositionChanged(verseId: String, verseNumber: Int) {
        guard let chapter = activeChapter, let book = activeBook else { return }
        prefsRepo.lastVerseId = verseId
        trackingRepo.recordReading(
            HistoryEntry(
                bibleAbbr: activeBibleAbbr,
                bibleName: activeBible,
                bookId: book.id,
                bookName: book.name,
                chapterId: chapter.id,
                chapterRef: chapter.reference,
                verseNumber: verseNumber
            )
        )
    }

    func consumeRestoreVerseTarget() {
        restoreVerseId = nil
    }

    func navigateChapter(_ direction: Int) {
        guard let index = activeChapterIndex, chapters.indices.contains(index + direction) else { return }
        selectChapter(chapters[index + direction])
    }

    func selectChapter(_ chapter: Chapter, scrollTarget: ScrollTarget? = nil) {
        Task { @MainActor in
            await loadVerses(
                abbr: activeBibleAbbr,
                chapter: chapter,
                scrollTarget: scrollTarget,
                forceScrollToFirstVerse: scrollTarget == nil
            )
        }
    }

    func selectBook(_ book: Book) {
        activeBook = book
        chapters = []
        Task { @MainActor in
            await loadChapters(abbr: activeBibleAbbr, book: book, chapterId: "", forceScrollToFirstVerse: true)
        }
    }

    func setPrimaryBible(_ abbr: String) {
        guard let chapter = activeChapter else { return }
        let newName = savedBibles.first { $0.abbreviation == abbr }?.name ?? activeBible
        prefsRepo.primaryBibleAbbr = abbr
        prefsRepo.lastBible = newName
        prefsRepo.secondaryBibles = prefsRepo.secondaryBibles.filter { $0 != abbr }
        activeBible = newName
        activeBibleAbbr = abbr

        let bookId = activeBook?.id ?? ""
        Task { @MainActor in
            await loadVerses(abbr: abbr, chapter: chapter)
            await loadBooks(abbr: abbr, bookId: bookId, chapterId: chapter.id)
        }
    }

    func jumpToQueueItem(_ item: ScriptureItem) {
        queueRepo.setActiveItem(item.id)
        let abbr = activeBibleAbbr
        Task { @MainActor in
            await loadBooks(abbr: abbr, bookId: item.bookId, chapterId: item.chapterId)
            restoreVerseId = item.verseId
            highlightQuery = nil
            prefsRepo.lastVerseId = item.verseId
        }
    }

    func dismissScriptureQueue() {
        queueRepo.dismiss()
    }

    func setFontSize(_ size: Double) {
        prefsRepo.fontSize = size
        fontSize = size
    }

    func setFontFamily(_ id: String) {
        prefsRepo.readerFontFamily = id
        fontFamilyId = id
    }

    func setReaderBackground(_ id: String) {
        prefsRepo.readerBackground = id
        readerBackgroundId = id
    }

    func toggleVerseSelected(_ verseId: String) {
        if selectedVerseIds.contains(verseId) {
            selectedVerseIds.remove(verseId)
        } else {
            selectedVerseIds.insert(verseId)
        }
    }

    func clearSelection() {
        selectedVerseIds = []
        showColorPicker = false
        pendingHighlightColor = nil
    }

    func quickToggleBookmark(_ verseId: String) {
        guard let book = activeBook, let chapter = activeChapter else { return }
        if bookmarks[verseId] != nil {
            annotationRepo.removeBookmarks(abbr: activeBibleAbbr, verseIds: [verseId])
            bookmarks.removeValue(forKey: verseId)
        } else {
            annotationRepo.setBookmarks(abbr: activeBibleAbbr, verseIds: [verseId], bookId: book.id, chapterId: chapter.id, colorHex: nil)
            bookmarks[verseId] = ""
        }
    }

    func requestNotes(forVerse verseId: String) {
        guard let verse = verses.first(where: { $0.verseId == verseId }) else { return }
        notesRequest = makeNotesRequest(for: verse)
    }

    func consumeNotesRequest() {
        notesRequest = nil
    }

    func openColorPicker() { showColorPicker = true }
    func dismissColorPicker() { showColorPicker = false }

    func chooseHighlightColor(_ hex: String) {
        pendingHighlightColor = hex
        showColorPicker = false
    }

    func cancelPendingHighlight() { pendingHighlightColor = nil }

    func openNotesForSelection() {
        guard selectedVerseIds.count == 1,
              let verseId = selectedVerseIds.first,
              let verse = verses.first(where: { $0.verseId == verseId }) else { return }
        notesRequest = makeNotesRequest(for: verse)
        selectedVerseIds = []
    }

    func confirmBookmarkOnly() {
        guard let color = pendingHighlightColor, let book = activeBook, let chapter = activeChapter else { return }
        let ids = Array(selectedVerseIds)
        annotationRepo.setBookmarks(abbr: activeBibleAbbr, verseIds: ids, bookId: book.id, chapterId: chapter.id, colorHex: color)
        ids.forEach { bookmarks[$0] = color }
        selectedVerseIds = []
        pendingHighlightColor = nil
    }

    func confirmBookmarkWithNotes() {
        guard let color = pendingHighlightColor, let book = activeBook, let chapter = activeChapter else { return }
        let ids = Array(selectedVerseIds)
        let ordered = verses.filter { selectedVerseIds.contains($0.verseId) }.sorted { $0.number < $1.number }
        guard let first = ordered.first else { return }

        annotationRepo.setBookmarks(abbr: activeBibleAbbr, verseIds: ids, bookId: book.id, chapterId: chapter.id, colorHex: color)
        ids.forEach { bookmarks[$0] = color }
        notesRequest = makeNotesRequest(for: first)
        selectedVerseIds = []
        pendingHighlightColor = nil
    }

    func refreshNotedVerses() {
        guard let chapter = activeChapter else { return }
        notedVerseIds = annotationRepo.notedVerseIds(abbr: activeBibleAbbr, chapterId: chapter.id)
    }

    private func makeNotesRequest(for verse: VerseDisplay) -> NotesRequest {
        let bookName = activeBook?.name ?? verse.bookId
        let chapterNumber = activeChapter?.number ?? ""
        return NotesRequest(
            bibleAbbr: activeBibleAbbr,
            verseId: verse.verseId,
            bookId: activeBook?.id ?? verse.bookId,
            chapterId: activeChapter?.id ?? verse.chapterId,
            title: "\(bookName) \(chapterNumber):\(verse.number)",
            verseText: verse.text
        )
    }

    func buildSelectionShareText() -> String? {
        let selected = verses.filter { selectedVerseIds.contains($0.verseId) }.sorted { $0.number < $1.number }
        guard !selected.isEmpty else { return nil }
        let reference = referencePrefix() + Self.formatVerseRange(selected.map(\.number))
        let body = selected.map { "\($0.number) \($0.text)" }.joined(separator: "\n")
        return shareText(reference: reference, body: body)
    }

    func buildActiveChapterShareText() -> String? {
        guard !verses.isEmpty else { return nil }
        var reference = referencePrefix()
        while let last = reference.last, last == ":" || last == " " { reference.removeLast() }
        let body = verses.sorted { $0.number < $1.number }.map { "\($0.number) \($0.text)" }.joined(separator: "\n")
        return shareText(reference: reference, body: body)
    }

    private func referencePrefix() -> String {
        let bookName = activeBook?.name ?? verses.first?.bookId ?? ""
        guard let number = activeChapter?.number, !number.trimmingCharacters(in: .whitespaces).isEmpty else {
            return "\(bookName) "
        }
        return "\(bookName) \(number):"
    }

    private func shareText(reference: String, body: String) -> String {
        var footnote = activeBible
        if let language = activeBibleLanguage, !language.trimmingCharacters(in: .whitespaces).isEmpty {
            footnote += " (\(language))"
        }
        return "\(reference)\n\n\(body)\n\n— \(footnote)"
    }

    static func formatVerseRange(_ numbers: [Int]) -> String {
        guard !numbers.isEmpty else { return "" }
        let sorted = numbers.sorted()
        var parts: [String] = []
        var start = sorted[0]
        var previous = sorted[0]

        for n in sorted.dropFirst() {
            if n == previous + 1 {
                previous = n
                continue
            }
            parts.append(start == previous ? "\(start)" : "\(start)-\(previous)")
            start = n
            previous = n
        }
        parts.append(start == previous ? "\(start)" : "\(start)-\(previous)")
        return parts.joined(separator: ", ")
    }
}
