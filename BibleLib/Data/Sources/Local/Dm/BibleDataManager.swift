//
//  BibleDataManager.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import CoreData

/// All access goes through `CoreDataManager.backgroundContext` (a private-queue
/// context) via `performAndWait`, so it is safe to call from any thread — including
/// the concurrent download tasks — and never touches the main queue. Bulk writes are
/// batched per call (one fetch + one save), the equivalent of Room's `insertAll`.
class BibleDataManager {
    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    private var context: NSManagedObjectContext {
        coreDataManager.backgroundContext
    }

    // MARK: - Bibles

    func fetchBibles() -> [Bible] {
        context.performAndWait {
            let request: NSFetchRequest<CDBible> = CDBible.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            return (try? context.fetch(request))?.map(MapCdToEntity.mapToEntity(_:)) ?? []
        }
    }

    /// Upserts metadata only — never touches download state, so re-fetching
    /// the Bible list can't accidentally wipe an existing download's progress.
    func saveBibles(_ bibles: [Bible]) {
        context.performAndWait {
            for bible in bibles {
                let cd = findOrCreateBible(abbreviation: bible.abbreviation)
                cd.name = bible.name
                cd.bibleDescription = bible.description
                cd.languageName = bible.languageName
                cd.scriptDirection = bible.scriptDirection
                cd.countryName = bible.countryName
                cd.path = bible.path
                cd.sortOrder = Int32(bible.sortOrder)
            }
            try? context.save()
        }
    }

    func updateProgress(abbr: String, progress: Double) {
        context.performAndWait {
            guard let cd = fetchBibleCd(abbr) else { return }
            cd.downloadProgress = progress
            cd.downloadFailed = false
            try? context.save()
        }
    }

    func markDownloaded(abbr: String) {
        context.performAndWait {
            guard let cd = fetchBibleCd(abbr) else { return }
            cd.isDownloaded = true
            cd.downloadProgress = 1.0
            cd.downloadFailed = false
            try? context.save()
        }
    }

    /// Keeps the last recorded progress so the UI can show "N% done before it stopped".
    func markFailed(abbr: String) {
        context.performAndWait {
            guard let cd = fetchBibleCd(abbr) else { return }
            cd.downloadFailed = true
            try? context.save()
        }
    }

    /// Must be called from inside `context.performAndWait`.
    private func fetchBibleCd(_ abbr: String) -> CDBible? {
        let request: NSFetchRequest<CDBible> = CDBible.fetchRequest()
        request.predicate = NSPredicate(format: "abbreviation == %@", abbr)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Must be called from inside `context.performAndWait`.
    private func findOrCreateBible(abbreviation: String) -> CDBible {
        if let existing = fetchBibleCd(abbreviation) { return existing }
        let new = CDBible(context: context)
        new.abbreviation = abbreviation
        new.addedAt = Date()
        return new
    }

    // MARK: - Books

    func saveBooks(_ books: [Book], for abbr: String) {
        context.performAndWait {
            let request: NSFetchRequest<CDBook> = CDBook.fetchRequest()
            request.predicate = NSPredicate(format: "bibleAbbr == %@", abbr)
            var existing: [String: CDBook] = [:]
            for row in (try? context.fetch(request)) ?? [] {
                if let id = row.id, existing[id] == nil { existing[id] = row }
            }

            for book in books {
                let cd: CDBook
                if let found = existing[book.id] {
                    cd = found
                } else {
                    cd = CDBook(context: context)
                    cd.id = book.id
                    cd.bibleAbbr = abbr
                }
                cd.abbreviation = book.abbreviation
                cd.name = book.name
                cd.nameLong = book.nameLong
                cd.sortOrder = Int32(book.sortOrder)
            }
            try? context.save()
            context.reset()
        }
    }

    func fetchBooks(for abbr: String) -> [Book] {
        context.performAndWait {
            let request: NSFetchRequest<CDBook> = CDBook.fetchRequest()
            request.predicate = NSPredicate(format: "bibleAbbr == %@", abbr)
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            return (try? context.fetch(request))?.map(MapCdToEntity.mapToEntity(_:)) ?? []
        }
    }

    // MARK: - Chapters

    func saveChapters(_ chapters: [Chapter], for abbr: String) {
        context.performAndWait {
            let request: NSFetchRequest<CDChapter> = CDChapter.fetchRequest()
            request.predicate = NSPredicate(format: "bibleAbbr == %@", abbr)
            var existing: [String: CDChapter] = [:]
            for row in (try? context.fetch(request)) ?? [] {
                if let id = row.id, existing[id] == nil { existing[id] = row }
            }

            for chapter in chapters {
                let cd: CDChapter
                if let found = existing[chapter.id] {
                    cd = found
                } else {
                    cd = CDChapter(context: context)
                    cd.id = chapter.id
                    cd.bibleAbbr = abbr
                }
                cd.bookId = chapter.bookId
                cd.number = chapter.number
                cd.reference = chapter.reference
            }
            try? context.save()
            context.reset()
        }
    }

    func fetchChapters(for abbr: String, bookId: String) -> [Chapter] {
        context.performAndWait {
            let request: NSFetchRequest<CDChapter> = CDChapter.fetchRequest()
            request.predicate = NSPredicate(format: "bibleAbbr == %@ AND bookId == %@", abbr, bookId)
            let all = (try? context.fetch(request))?.map(MapCdToEntity.mapToEntity(_:)) ?? []
            // Chapter numbers are stored as strings, so sort numerically rather than lexically.
            return all.sorted { (Int($0.number) ?? 0) < (Int($1.number) ?? 0) }
        }
    }

    // MARK: - Verses

    /// Chapter ids already cached for this Bible, so a resumed download can
    /// skip chapters it already has (mirrors Android's getCachedChapterIds).
    /// Reads only the id column so it doesn't load every chapter's verse JSON.
    func cachedChapterIds(for abbr: String) -> Set<String> {
        context.performAndWait {
            let request = NSFetchRequest<NSDictionary>(entityName: "CDVerse")
            request.predicate = NSPredicate(format: "bibleAbbr == %@", abbr)
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["chapterId"]
            let rows = (try? context.fetch(request)) ?? []
            return Set(rows.compactMap { $0["chapterId"] as? String })
        }
    }

    func saveVerseContent(_ content: VerseChapterContent) {
        saveVerseContents([content])
    }

    /// Saves many chapters of one Bible in a single fetch + save (Android: `verseDao.insertAll`).
    func saveVerseContents(_ contents: [VerseChapterContent]) {
        guard let abbr = contents.first?.bibleAbbr else { return }

        context.performAndWait {
            let request: NSFetchRequest<CDVerse> = CDVerse.fetchRequest()
            request.predicate = NSPredicate(
                format: "bibleAbbr == %@ AND chapterId IN %@", abbr, contents.map(\.chapterId)
            )
            var existing: [String: CDVerse] = [:]
            for row in (try? context.fetch(request)) ?? [] {
                if let id = row.chapterId, existing[id] == nil { existing[id] = row }
            }

            let encoder = JSONEncoder()
            for content in contents {
                let cd = existing[content.chapterId] ?? CDVerse(context: context)
                cd.chapterId = content.chapterId
                cd.bibleAbbr = content.bibleAbbr
                cd.bookId = content.bookId
                cd.verseCount = Int32(content.verseCount)
                cd.contentJson = (try? encoder.encode(content.verses))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
                cd.cachedAt = Date()
            }
            try? context.save()
            context.reset() // release the verse JSON we just wrote
        }
    }

    func fetchVerseContent(for abbr: String, chapterId: String) -> VerseChapterContent? {
        context.performAndWait {
            let request: NSFetchRequest<CDVerse> = CDVerse.fetchRequest()
            request.predicate = NSPredicate(format: "chapterId == %@ AND bibleAbbr == %@", chapterId, abbr)
            request.fetchLimit = 1
            guard let cd = try? context.fetch(request).first else { return nil }
            return MapCdToEntity.mapToEntity(cd)
        }
    }

    // MARK: - Per-Bible cleanup

    /// Removes a Bible and everything downloaded for it (mirrors Android's
    /// `BibleRepo.deleteBible`).
    func deleteBible(abbr: String) {
        context.performAndWait {
            batchDeleteContent(for: abbr)
            context.reset()
            if let cd = fetchBibleCd(abbr) { context.delete(cd) }
            try? context.save()
        }
    }

    /// Drops a Bible's books/chapters/verses and resets its download state so
    /// it can be downloaded again from scratch (mirrors Android's
    /// `BibleRepo.clearBibleContent`).
    func clearBibleContent(abbr: String) {
        context.performAndWait {
            batchDeleteContent(for: abbr)
            context.reset()
            if let cd = fetchBibleCd(abbr) {
                cd.isDownloaded = false
                cd.downloadProgress = 0
                cd.downloadFailed = false
            }
            try? context.save()
        }
    }

    /// Must be called from inside `context.performAndWait`.
    private func batchDeleteContent(for abbr: String) {
        for entity in ["CDVerse", "CDChapter", "CDBook"] {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            fetch.predicate = NSPredicate(format: "bibleAbbr == %@", abbr)
            _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: fetch))
        }
    }

    func deleteAllData() {
        context.performAndWait {
            for name in ["CDBible", "CDBook", "CDChapter", "CDVerse"] {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: request))
            }
            context.reset()
        }
    }
}
