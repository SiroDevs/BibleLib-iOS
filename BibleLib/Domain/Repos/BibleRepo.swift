//
//  BibleRepo.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

protocol BibleRepoProtocol {
    func fetchAvailableBibles() async throws -> [BibleInfoDTO]
    func saveBibles(_ bibles: [Bible])
    func localBibles() -> [Bible]
    func downloadBible(abbr: String, onProgress: @escaping (String, Double) -> Void) async throws
    func localBooks(abbr: String) -> [Book]
    func localChapters(abbr: String, bookId: String) -> [Chapter]
    func localVerses(abbr: String, chapterId: String) -> VerseChapterContent?
    func deleteBible(abbr: String)
    func clearBibleContent(abbr: String)
    func markDownloadFailed(abbr: String)
}

final class BibleRepo: BibleRepoProtocol {
    private let api: BibleLibApiServiceProtocol
    private let bibleData: BibleDataManager

    private let maxConcurrentBooks = 20

    init(api: BibleLibApiServiceProtocol, bibleData: BibleDataManager) {
        self.api = api
        self.bibleData = bibleData
    }

    func fetchAvailableBibles() async throws -> [BibleInfoDTO] {
        let api = self.api
        let groups = try await RetryPolicy.retrying { try await api.fetchGroups() }

        return await withTaskGroup(of: (Int, [BibleInfoDTO]).self) { taskGroup in
            for (index, group) in groups.enumerated() {
                taskGroup.addTask {
                    do {
                        return (index, try await RetryPolicy.retrying { try await api.fetchGroupInfo(group: group) })
                    } catch {
                        print("⚠️ Couldn't fetch group '\(group)', skipping: \(error.localizedDescription)")
                        return (index, [])
                    }
                }
            }
            var results: [(Int, [BibleInfoDTO])] = []
            for await result in taskGroup { results.append(result) }
            return results.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
        }
    }

    private func resolvePath(_ abbr: String) -> String {
        let path = bibleData.fetchBibles().first { $0.abbreviation == abbr }?.path ?? ""
        return path.isEmpty ? abbr : path
    }

    func saveBibles(_ bibles: [Bible]) {
        bibleData.saveBibles(bibles)
    }

    func localBibles() -> [Bible] {
        bibleData.fetchBibles()
    }

    func downloadBible(abbr: String, onProgress: @escaping (String, Double) -> Void = { _, _ in }) async throws {
        let path = resolvePath(abbr)
        let api = self.api
        print("▶ Downloading \(abbr) bible from path=\(path)")

        func report(_ step: String, _ progress: Double) {
            bibleData.updateProgress(abbr: abbr, progress: progress)
            onProgress(step, progress)
        }

        do {
            report("Fetching books...", 0.05)
            let bookDTOs = try await RetryPolicy.retrying { try await api.fetchBooks(path: path) }
            let books = bookDTOs.enumerated().map { index, dto in
                Book(id: dto.id, bibleAbbr: abbr, abbreviation: dto.abbreviation, name: dto.name, nameLong: dto.nameLong, sortOrder: index)
            }
            bibleData.saveBooks(books, for: abbr)
            print("✅ \(books.count) books saved for \(abbr)")

            report("Fetching chapters...", 0.15)
            let chaptersResp = try await RetryPolicy.retrying { try await api.fetchChapters(path: path) }
            var chapters: [Chapter] = []
            for (_, chapterDTOs) in chaptersResp {
                for dto in chapterDTOs {
                    chapters.append(Chapter(id: dto.id, bibleAbbr: abbr, bookId: dto.bookId, number: dto.number, reference: dto.reference))
                }
            }
            bibleData.saveChapters(chapters, for: abbr)
            print("✅ \(chapters.count) chapters saved for \(abbr)")

            let chaptersByBook = Dictionary(grouping: chapters, by: { $0.bookId })
            let bookIds = books.map(\.id).filter { !(chaptersByBook[$0]?.isEmpty ?? true) }
            let alreadyCached = bibleData.cachedChapterIds(for: abbr)

            report("Fetching verses...", 0.25)
            try await downloadVersesForAllBooks(abbr: abbr, path: path, bookIds: bookIds, chaptersByBook: chaptersByBook, alreadyCached: alreadyCached, report: report)

            bibleData.markDownloaded(abbr: abbr)
            onProgress("Done!", 1.0)
            print("✅ Download complete for \(abbr)")
        } catch {
            // A cancelled download (bible removed, restart requested) isn't a failure.
            if !RetryPolicy.isCancellation(error) {
                bibleData.markFailed(abbr: abbr)
            }
            throw error
        }
    }

    private func downloadVersesForAllBooks(
        abbr: String,
        path: String,
        bookIds: [String],
        chaptersByBook: [String: [Chapter]],
        alreadyCached: Set<String>,
        report: (String, Double) -> Void
    ) async throws {
        guard !bookIds.isEmpty else { return }
        var completed = 0

        try await withThrowingTaskGroup(of: String.self) { group in
            var iterator = bookIds.makeIterator()

            for _ in 0..<min(maxConcurrentBooks, bookIds.count) {
                guard let bookId = iterator.next() else { break }
                let chapters = chaptersByBook[bookId] ?? []
                group.addTask {
                    try await self.downloadBook(abbr: abbr, path: path, bookId: bookId, chapters: chapters, alreadyCached: alreadyCached)
                    return bookId
                }
            }

            while let finishedBookId = try await group.next() {
                completed += 1
                let fraction = Double(completed) / Double(bookIds.count)
                report("Fetching verses (\(finishedBookId), \(completed)/\(bookIds.count))...", 0.25 + fraction * 0.7)

                if let bookId = iterator.next() {
                    let chapters = chaptersByBook[bookId] ?? []
                    group.addTask {
                        try await self.downloadBook(abbr: abbr, path: path, bookId: bookId, chapters: chapters, alreadyCached: alreadyCached)
                        return bookId
                    }
                }
            }
        }
    }

    private func downloadBook(abbr: String, path: String, bookId: String, chapters: [Chapter], alreadyCached: Set<String>) async throws {
        do {
            let pending = chapters.filter { !alreadyCached.contains($0.id) }
            guard !pending.isEmpty else { return }

            let contents = try await fetchVersesForBook(abbr: abbr, path: path, bookId: bookId, chapters: pending)
            if !contents.isEmpty {
                bibleData.saveVerseContents(contents)
            }
        } catch {
            if RetryPolicy.isCancellation(error) { throw error }
            print("⚠️ Book \(bookId) failed for \(abbr), continuing with others: \(error.localizedDescription)")
        }
    }

    private func fetchVersesForBook(abbr: String, path: String, bookId: String, chapters: [Chapter]) async throws -> [VerseChapterContent] {
        let api = self.api
        var results: [VerseChapterContent] = []

        for chapter in chapters {
            try Task.checkCancellation()
            do {
                let content = try await RetryPolicy.retrying {
                    try await api.fetchVerses(path: path, bookId: bookId, chapter: chapter.number)
                }
                let verses = Self.extractVerses(from: content)
                results.append(
                    VerseChapterContent(chapterId: chapter.id, bibleAbbr: abbr, bookId: bookId, verseCount: content.verseCount, verses: verses)
                )
            } catch {
                if RetryPolicy.isCancellation(error) { throw error }
                print("⚠️ Skipping unparseable chapter \(bookId)/\(chapter.number) for \(abbr): \(error.localizedDescription)")
            }
        }
        return results
    }

    static func extractVerses(from content: ChapterContentDTO) -> [VerseDisplay] {
        var verses: [VerseDisplay] = []
        var currentVerseNumber = 0

        func walk(_ items: [ContentItemDTO?]) {
            for case let item? in items {
                if item.type == "tag", item.name == "verse" {
                    if let numberString = item.attrs?["number"], let number = Int(numberString) {
                        currentVerseNumber = number
                    }
                } else if item.type == "text", let text = item.text {
                    let verseId = item.attrs?["verseId"] ?? ""
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !verseId.isEmpty, !trimmed.isEmpty, currentVerseNumber > 0 {
                        if let idx = verses.lastIndex(where: { $0.verseId == verseId }) {
                            verses[idx].text += " " + trimmed
                        } else {
                            verses.append(
                                VerseDisplay(verseId: verseId, number: currentVerseNumber, text: trimmed, chapterId: content.id, bookId: content.bookId)
                            )
                        }
                    }
                }
                if let children = item.items {
                    walk(children)
                }
            }
        }

        walk(content.content)
        return verses.sorted { $0.number < $1.number }
    }

    func localBooks(abbr: String) -> [Book] {
        bibleData.fetchBooks(for: abbr)
    }

    func localChapters(abbr: String, bookId: String) -> [Chapter] {
        bibleData.fetchChapters(for: abbr, bookId: bookId)
    }

    func localVerses(abbr: String, chapterId: String) -> VerseChapterContent? {
        bibleData.fetchVerseContent(for: abbr, chapterId: chapterId)
    }

    func deleteBible(abbr: String) {
        bibleData.deleteBible(abbr: abbr)
    }

    func clearBibleContent(abbr: String) {
        bibleData.clearBibleContent(abbr: abbr)
    }

    func markDownloadFailed(abbr: String) {
        bibleData.markFailed(abbr: abbr)
    }
}
