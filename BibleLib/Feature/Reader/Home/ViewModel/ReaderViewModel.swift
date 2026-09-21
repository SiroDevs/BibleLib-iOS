//
//  ReaderViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import Foundation
import Combine

final class ReaderViewModel: ObservableObject {
    @Published private(set) var uiState: UiState = .loading(nil)
    @Published private(set) var bibles: [Bible] = []
    @Published private(set) var activeBibleAbbr = ""
    @Published private(set) var books: [Book] = []
    @Published private(set) var activeBook: Book?
    @Published private(set) var chapters: [Chapter] = []
    @Published private(set) var activeChapter: Chapter?
    @Published private(set) var verses: [VerseDisplay] = []
    @Published private(set) var parallel: [ParallelChapter] = []
    @Published private(set) var queueItems: [ScriptureItem] = []
    @Published private(set) var queueActiveItemId: Int64?
    @Published var scrollTarget: ScrollTarget?

    let selection: VerseSelectionModel

    private let bibleRepo: BibleRepoProtocol
    private let prefs: PrefsRepo
    private let queue: ScriptureQueueRepo
    private let progress: ReadingProgress
    private var isFirstLoad = true
    private var cancellables = Set<AnyCancellable>()

    init(bibleRepo: BibleRepoProtocol, prefs: PrefsRepo, annotations: AnnotationRepo, tracking: TrackingRepo, queue: ScriptureQueueRepo) {
        self.bibleRepo = bibleRepo
        self.prefs = prefs
        self.queue = queue
        self.selection = VerseSelectionModel(annotations: annotations)
        self.progress = ReadingProgress(prefs: prefs, tracking: tracking, queue: queue)
        bindQueue()
    }

    var activeBible: Bible? { bibles.first { $0.abbreviation == activeBibleAbbr } }
    var isQueueActive: Bool { queueItems.count > 1 }

    var context: ChapterContext? {
        guard let book = activeBook, let chapter = activeChapter else { return nil }
        return ChapterContext(abbr: activeBibleAbbr, book: book, chapter: chapter, verses: verses)
    }

    private var chapterIndex: Int? { chapters.firstIndex { $0.id == activeChapter?.id } }
    var hasPrevChapter: Bool { (chapterIndex ?? 0) > 0 }
    var hasNextChapter: Bool { chapterIndex.map { $0 < chapters.count - 1 } ?? false }
    var prevChapterLabel: String { chapterIndex.flatMap { $0 > 0 ? chapters[$0 - 1].reference : nil } ?? "Previous chapter" }
    var nextChapterLabel: String { hasNextChapter ? chapters[(chapterIndex ?? 0) + 1].reference : "Next chapter" }

    func open(_ target: ReaderTarget? = nil) {
        bibles = bibleRepo.localBibles()
        let wanted = target?.bibleAbbr.nonEmpty ?? prefs.lastBibleAbbr.nonEmpty ?? prefs.primaryBibleAbbr ?? ""
        guard let abbr = bibles.first(where: { $0.abbreviation == wanted })?.abbreviation ?? bibles.first?.abbreviation else {
            uiState = .error("No Bibles downloaded yet.")
            return
        }
        isFirstLoad = true
        activeBibleAbbr = abbr
        let scroll = target.flatMap { t in t.verseId.nonEmpty.map { ScrollTarget(verseId: $0, highlightQuery: t.searchQuery.nonEmpty) } }
        loadBooks(bookId: target?.bookId ?? "", chapterId: target?.chapterId ?? "", scroll: scroll)
    }

    func refresh() {
        guard !activeBibleAbbr.isEmpty else { return }
        bibles = bibleRepo.localBibles()
        let wanted = prefs.lastBibleAbbr.nonEmpty ?? prefs.primaryBibleAbbr ?? activeBibleAbbr
        if wanted != activeBibleAbbr || activeBible == nil { return open() }

        if let chapter = activeChapter { parallel = loadParallel(chapter) }
        selection.reloadMarkers()
    }

    func navigateChapter(_ step: Int) {
        guard let index = chapterIndex, chapters.indices.contains(index + step) else { return }
        loadVerses(chapters[index + step], startAtTop: true)
    }

    func select(_ chapter: Chapter) { loadVerses(chapter, startAtTop: true) }

    func select(_ book: Book) {
        guard book.id != activeBook?.id else { return }
        loadChapters(in: book, chapterId: "", startAtTop: true)
    }

    func setPrimary(_ abbr: String) {
        guard let bible = bibles.first(where: { $0.abbreviation == abbr }), let chapter = activeChapter else { return }
        prefs.primaryBibleAbbr = abbr
        prefs.lastBible = bible.name
        prefs.secondaryBibles = prefs.secondaryBibles.filter { $0 != abbr }
        activeBibleAbbr = abbr
        loadBooks(bookId: activeBook?.id ?? "", chapterId: chapter.id, scroll: nil)
    }

    func jump(to item: ScriptureItem) {
        queue.setActiveItem(item.id)
        loadBooks(bookId: item.bookId, chapterId: item.chapterId, scroll: ScrollTarget(verseId: item.verseId))
    }

    func dismissQueue() { queue.dismiss() }

    func verseViewed(_ verse: VerseDisplay) {
        guard let context else { return }
        progress.verseViewed(verse, in: context, bibleName: activeBible?.name ?? "")
    }

    private func loadBooks(bookId: String, chapterId: String, scroll: ScrollTarget?) {
        let loaded = bibleRepo.localBooks(abbr: activeBibleAbbr)
        guard !loaded.isEmpty else {
            uiState = .error("Bible data not available. Please wait for the download to complete.")
            return
        }
        books = loaded
        let id = bookId.nonEmpty ?? prefs.lastBookId
        loadChapters(in: loaded.first { $0.id == id } ?? loaded[0], chapterId: chapterId.nonEmpty ?? prefs.lastChapterId, scroll: scroll)
    }

    private func loadChapters(in book: Book, chapterId: String, scroll: ScrollTarget? = nil, startAtTop: Bool = false) {
        let loaded = bibleRepo.localChapters(abbr: activeBibleAbbr, bookId: book.id)
        guard !loaded.isEmpty else {
            uiState = .error("No chapters found for \(book.name)")
            return
        }
        activeBook = book
        chapters = loaded
        loadVerses(loaded.first { $0.id == chapterId } ?? loaded[0], scroll: scroll, startAtTop: startAtTop)
    }

    private func loadVerses(_ chapter: Chapter, scroll: ScrollTarget? = nil, startAtTop: Bool = false) {
        guard let content = bibleRepo.localVerses(abbr: activeBibleAbbr, chapterId: chapter.id) else {
            uiState = .error("Verses not cached. Please ensure download is complete.")
            return
        }
        activeChapter = chapter
        verses = content.verses
        parallel = loadParallel(chapter)
        scrollTarget = scroll ?? (startAtTop ? verses.first.map { ScrollTarget(verseId: $0.verseId) } : savedScrollTarget())
        isFirstLoad = false
        uiState = .loaded

        guard let context else { return }
        selection.load(context)
        progress.chapterLoaded(context, bibleName: activeBible?.name ?? "")
    }

    private func savedScrollTarget() -> ScrollTarget? {
        isFirstLoad ? prefs.lastVerseId.nonEmpty.map { ScrollTarget(verseId: $0) } : nil
    }

    private func loadParallel(_ chapter: Chapter) -> [ParallelChapter] {
        ParallelChapter.load(primary: activeBibleAbbr, chapterId: chapter.id, bibles: bibles, prefs: prefs, repo: bibleRepo)
    }

    private func bindQueue() {
        Publishers.CombineLatest(queue.$items, queue.$activeItemId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items, activeId in
                self?.queueItems = items
                self?.queueActiveItemId = activeId
            }
            .store(in: &cancellables)

        selection.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
