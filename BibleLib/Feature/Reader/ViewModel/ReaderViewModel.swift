//
//  ReaderViewModel.swift
//  BibleLib
//
//  Bare-minimum stand-in for Android's Reader controllers: loads books for
//  the given Bible, walks chapters within a book and across book boundaries,
//  and reads cached verse content back from Core Data. No parallel Bibles,
//  annotations, downloads-from-the-reader, page curl, or scripture queue
//  yet — those are later steps.
//

import Foundation

final class ReaderViewModel: ObservableObject {
    let bibleAbbr: String

    @Published var books: [Book] = []
    @Published var chapters: [Chapter] = []
    @Published var currentBookIndex: Int = 0
    @Published var currentChapterIndex: Int = 0
    @Published var verses: [VerseDisplay] = []
    @Published var uiState: UiState = .idle

    private let bibleRepo: BibleRepoProtocol

    init(bibleAbbr: String, bibleRepo: BibleRepoProtocol) {
        self.bibleAbbr = bibleAbbr
        self.bibleRepo = bibleRepo
    }

    var currentBook: Book? {
        books.indices.contains(currentBookIndex) ? books[currentBookIndex] : nil
    }

    var currentChapter: Chapter? {
        chapters.indices.contains(currentChapterIndex) ? chapters[currentChapterIndex] : nil
    }

    var canGoPrevious: Bool {
        currentChapterIndex > 0 || currentBookIndex > 0
    }

    var canGoNext: Bool {
        currentChapterIndex + 1 < chapters.count || currentBookIndex + 1 < books.count
    }

    @MainActor
    func load() {
        books = bibleRepo.localBooks(abbr: bibleAbbr)
        guard let firstBook = books.first else {
            uiState = .error("No books found for this Bible yet. Try re-downloading it from Selection.")
            return
        }
        currentBookIndex = 0
        loadChapters(for: firstBook)
    }

    @MainActor
    private func loadChapters(for book: Book) {
        chapters = bibleRepo.localChapters(abbr: bibleAbbr, bookId: book.id)
        currentChapterIndex = 0
        loadCurrentChapterContent()
    }

    @MainActor
    private func loadCurrentChapterContent() {
        guard let chapter = currentChapter else {
            uiState = .error("No chapters found for this book yet.")
            return
        }
        if let content = bibleRepo.localVerses(abbr: bibleAbbr, chapterId: chapter.id) {
            verses = content.verses
            uiState = .loaded
        } else {
            verses = []
            uiState = .error("This chapter hasn't been downloaded yet.")
        }
    }

    @MainActor
    func nextChapter() {
        if currentChapterIndex + 1 < chapters.count {
            currentChapterIndex += 1
            loadCurrentChapterContent()
        } else if currentBookIndex + 1 < books.count {
            currentBookIndex += 1
            loadChapters(for: books[currentBookIndex])
        }
    }

    @MainActor
    func previousChapter() {
        if currentChapterIndex > 0 {
            currentChapterIndex -= 1
            loadCurrentChapterContent()
        } else if currentBookIndex > 0 {
            currentBookIndex -= 1
            let previousBook = books[currentBookIndex]
            chapters = bibleRepo.localChapters(abbr: bibleAbbr, bookId: previousBook.id)
            currentChapterIndex = max(chapters.count - 1, 0)
            loadCurrentChapterContent()
        }
    }
}
