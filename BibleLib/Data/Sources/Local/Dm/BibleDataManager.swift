//
//  BibleDataManager.swift
//  BibleLib
//
//  Same pattern as SwahiLib's WordDataManager, scoped to the 4 entities
//  step 1 needs. Note: this writes through the main-queue viewContext
//  (wrapped in `performAndWait`) rather than a private background context
//  — fine for a bare-minimum single-Bible download, but a real background
//  context is worth adding once whole-Bible downloads need to feel fast.
//

import CoreData

class BibleDataManager {
    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }

    // MARK: - Bibles

    func fetchBibles() -> [Bible] {
        let request: NSFetchRequest<CDBible> = CDBible.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        return (try? context.fetch(request))?.map(MapCdToEntity.mapToEntity(_:)) ?? []
    }

    /// Upserts metadata only — never touches download state, so re-fetching
    /// info.json can't accidentally wipe an existing download's progress.
    func saveBibles(_ bibles: [Bible]) {
        context.performAndWait {
            for bible in bibles {
                let cd = findOrCreateBible(abbreviation: bible.abbreviation)
                cd.name = bible.name
                cd.bibleDescription = bible.description
                cd.languageName = bible.languageName
                cd.scriptDirection = bible.scriptDirection
                cd.countryName = bible.countryName
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

    // MARK: - Books

    func saveBooks(_ books: [Book], for abbr: String) {
        context.performAndWait {
            for book in books {
                let cd = findOrCreateBook(id: book.id, abbr: abbr)
                cd.abbreviation = book.abbreviation
                cd.name = book.name
                cd.nameLong = book.nameLong
                cd.sortOrder = Int32(book.sortOrder)
            }
            try? context.save()
        }
    }

    func fetchBooks(for abbr: String) -> [Book] {
        let request: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        request.predicate = NSPredicate(format: "bibleAbbr == %@", abbr)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        return (try? context.fetch(request))?.map(MapCdToEntity.mapToEntity(_:)) ?? []
    }

    private func findOrCreateBook(id: String, abbr: String) -> CDBook {
        let request: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND bibleAbbr == %@", id, abbr)
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first { return existing }
        let new = CDBook(context: context)
        new.id = id
        new.bibleAbbr = abbr
        return new
    }

    // MARK: - Chapters

    func saveChapters(_ chapters: [Chapter], for abbr: String) {
        context.performAndWait {
            for chapter in chapters {
                let cd = findOrCreateChapter(id: chapter.id, abbr: abbr)
                cd.bookId = chapter.bookId
                cd.number = chapter.number
                cd.reference = chapter.reference
            }
            try? context.save()
        }
    }

    func fetchChapters(for abbr: String, bookId: String) -> [Chapter] {
        let request: NSFetchRequest<CDChapter> = CDChapter.fetchRequest()
        request.predicate = NSPredicate(format: "bibleAbbr == %@ AND bookId == %@", abbr, bookId)
        let all = (try? context.fetch(request))?.map(MapCdToEntity.mapToEntity(_:)) ?? []
        // Chapter numbers are stored as strings, so sort numerically rather than lexically.
        return all.sorted { (Int($0.number) ?? 0) < (Int($1.number) ?? 0) }
    }

    private func findOrCreateChapter(id: String, abbr: String) -> CDChapter {
        let request: NSFetchRequest<CDChapter> = CDChapter.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND bibleAbbr == %@", id, abbr)
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first { return existing }
        let new = CDChapter(context: context)
        new.id = id
        new.bibleAbbr = abbr
        return new
    }

    // MARK: - Verses

    /// Chapter ids already cached for this Bible, so a resumed download can
    /// skip chapters it already has (mirrors Android's getCachedChapterIds).
    func cachedChapterIds(for abbr: String) -> Set<String> {
        let request: NSFetchRequest<CDVerse> = CDVerse.fetchRequest()
        request.predicate = NSPredicate(format: "bibleAbbr == %@", abbr)
        let rows = (try? context.fetch(request)) ?? []
        return Set(rows.compactMap(\.chapterId))
    }

    func saveVerseContent(_ content: VerseChapterContent) {
        context.performAndWait {
            let request: NSFetchRequest<CDVerse> = CDVerse.fetchRequest()
            request.predicate = NSPredicate(
                format: "chapterId == %@ AND bibleAbbr == %@", content.chapterId, content.bibleAbbr
            )
            request.fetchLimit = 1
            let cd = (try? context.fetch(request).first) ?? CDVerse(context: context)
            cd.chapterId = content.chapterId
            cd.bibleAbbr = content.bibleAbbr
            cd.bookId = content.bookId
            cd.verseCount = Int32(content.verseCount)
            cd.contentJson = (try? JSONEncoder().encode(content.verses))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
            cd.cachedAt = Date()
            try? context.save()
        }
    }

    func fetchVerseContent(for abbr: String, chapterId: String) -> VerseChapterContent? {
        let request: NSFetchRequest<CDVerse> = CDVerse.fetchRequest()
        request.predicate = NSPredicate(format: "chapterId == %@ AND bibleAbbr == %@", chapterId, abbr)
        request.fetchLimit = 1
        guard let cd = try? context.fetch(request).first else { return nil }
        return MapCdToEntity.mapToEntity(cd)
    }

    func deleteAllData() {
        context.performAndWait {
            for name in ["CDBible", "CDBook", "CDChapter", "CDVerse"] {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let delete = NSBatchDeleteRequest(fetchRequest: request)
                try? context.execute(delete)
            }
            try? context.save()
        }
    }
}
