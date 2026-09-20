//
//  BibleDataManager.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import CoreData

class BibleDataManager {
    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    private var context: NSManagedObjectContext {
        coreDataManager.backgroundContext
    }

    func fetchBibles() -> [Bible] {
        context.performAndWait {
            let request: NSFetchRequest<CDBible> = CDBible.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            return (try? context.fetch(request))?.map(MapCdToEntity.mapToEntity(_:)) ?? []
        }
    }

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

    func markFailed(abbr: String) {
        context.performAndWait {
            guard let cd = fetchBibleCd(abbr) else { return }
            cd.downloadFailed = true
            try? context.save()
        }
    }

    private func fetchBibleCd(_ abbr: String) -> CDBible? {
        let request: NSFetchRequest<CDBible> = CDBible.fetchRequest()
        request.predicate = NSPredicate(format: "abbreviation == %@", abbr)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func findOrCreateBible(abbreviation: String) -> CDBible {
        if let existing = fetchBibleCd(abbreviation) { return existing }
        let new = CDBible(context: context)
        new.abbreviation = abbreviation
        new.addedAt = Date()
        return new
    }

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
            context.reset()
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

    /// Full-text search over one Bible's downloaded chapters. The stored JSON is
    /// pre-filtered in SQLite, then each verse is checked (Android: `searchInBible`).
    func searchVerses(abbr: String, query: String) -> [VerseDisplay] {
        context.performAndWait {
            let request: NSFetchRequest<CDVerse> = CDVerse.fetchRequest()
            request.predicate = NSPredicate(format: "bibleAbbr == %@ AND contentJson CONTAINS[cd] %@", abbr, query)
            let rows = (try? context.fetch(request)) ?? []
            let chapters = rows.map(MapCdToEntity.mapToEntity(_:))
            context.reset()
            return chapters.flatMap { chapter in
                chapter.verses.filter { $0.text.localizedCaseInsensitiveContains(query) }
            }
        }
    }

    func deleteBible(abbr: String) {
        context.performAndWait {
            batchDeleteContent(for: abbr)
            context.reset()
            if let cd = fetchBibleCd(abbr) { context.delete(cd) }
            try? context.save()
        }
    }

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
