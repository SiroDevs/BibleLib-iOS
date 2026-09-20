//
//  UserDataManager.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//


import CoreData

final class UserDataManager {
    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    private var context: NSManagedObjectContext { coreDataManager.backgroundContext }
    
    private func fetch<T: NSManagedObject>(
        _ entity: String,
        predicate: NSPredicate? = nil,
        sort: [NSSortDescriptor] = [],
        limit: Int = 0
    ) -> [T] {
        let request = NSFetchRequest<T>(entityName: entity)
        request.predicate = predicate
        request.sortDescriptors = sort.isEmpty ? nil : sort
        request.fetchLimit = limit
        return (try? context.fetch(request)) ?? []
    }

    private func deleteAll(_ entity: String, predicate: NSPredicate? = nil) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        request.predicate = predicate
        _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: request))
        context.reset()
    }

    private func nextId(_ entity: String, key: String) -> Int64 {
        let request = NSFetchRequest<NSDictionary>(entityName: entity)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = [key]
        request.sortDescriptors = [NSSortDescriptor(key: key, ascending: false)]
        request.fetchLimit = 1
        let current = (try? context.fetch(request))?.first?[key] as? Int64 ?? 0
        return current + 1
    }

    private func save() { try? context.save() }

    func bookmarks(abbr: String, chapterId: String) -> [String: String] {
        context.performAndWait {
            let rows: [CDBookmark] = fetch(
                "CDBookmark", predicate: NSPredicate(format: "bibleAbbr == %@ AND chapterId == %@", abbr, chapterId)
            )
            var result: [String: String] = [:]
            for row in rows { if let id = row.verseId { result[id] = row.colorHex ?? "" } }
            return result
        }
    }

    func allBookmarks() -> [Bookmark] {
        context.performAndWait {
            let rows: [CDBookmark] = fetch("CDBookmark", sort: [NSSortDescriptor(key: "createdAt", ascending: false)])
            return rows.map(MapCdToEntity.mapToEntity(_:))
        }
    }

    func setBookmarks(abbr: String, verseIds: [String], bookId: String, chapterId: String, colorHex: String?) {
        guard !verseIds.isEmpty else { return }
        context.performAndWait {
            let existing: [CDBookmark] = fetch(
                "CDBookmark", predicate: NSPredicate(format: "bibleAbbr == %@ AND verseId IN %@", abbr, verseIds)
            )
            var byVerse: [String: CDBookmark] = [:]
            for row in existing { if let id = row.verseId { byVerse[id] = row } }

            for verseId in verseIds {
                let cd = byVerse[verseId] ?? CDBookmark(context: context)
                cd.verseId = verseId
                cd.bibleAbbr = abbr
                cd.bookId = bookId
                cd.chapterId = chapterId
                cd.colorHex = colorHex
                cd.createdAt = Date()
            }
            save()
        }
    }

    func removeBookmarks(abbr: String, verseIds: [String]) {
        guard !verseIds.isEmpty else { return }
        context.performAndWait {
            deleteAll("CDBookmark", predicate: NSPredicate(format: "bibleAbbr == %@ AND verseId IN %@", abbr, verseIds))
        }
    }

    func deleteAllBookmarks() {
        context.performAndWait { deleteAll("CDBookmark") }
    }

    func note(abbr: String, verseId: String) -> Note? {
        context.performAndWait {
            let rows: [CDNote] = fetch(
                "CDNote", predicate: NSPredicate(format: "bibleAbbr == %@ AND verseId == %@", abbr, verseId), limit: 1
            )
            return rows.first.map(MapCdToEntity.mapToEntity(_:))
        }
    }

    func notedVerseIds(abbr: String, chapterId: String) -> Set<String> {
        context.performAndWait {
            let rows: [CDNote] = fetch(
                "CDNote", predicate: NSPredicate(format: "bibleAbbr == %@ AND chapterId == %@", abbr, chapterId)
            )
            return Set(rows.compactMap(\.verseId))
        }
    }

    func allNotes() -> [Note] {
        context.performAndWait {
            let rows: [CDNote] = fetch("CDNote", sort: [NSSortDescriptor(key: "updatedAt", ascending: false)])
            return rows.map(MapCdToEntity.mapToEntity(_:))
        }
    }

    func saveNote(_ note: Note) {
        context.performAndWait {
            let existing: [CDNote] = fetch(
                "CDNote", predicate: NSPredicate(format: "bibleAbbr == %@ AND verseId == %@", note.bibleAbbr, note.verseId), limit: 1
            )
            let cd = existing.first ?? CDNote(context: context)
            cd.verseId = note.verseId
            cd.bibleAbbr = note.bibleAbbr
            cd.bookId = note.bookId
            cd.chapterId = note.chapterId
            cd.title = note.title
            cd.verseText = note.verseText
            cd.noteText = note.noteText
            cd.updatedAt = Date()
            save()
        }
    }

    func deleteNote(abbr: String, verseId: String) {
        context.performAndWait {
            deleteAll("CDNote", predicate: NSPredicate(format: "bibleAbbr == %@ AND verseId == %@", abbr, verseId))
        }
    }

    func deleteAllNotes() {
        context.performAndWait { deleteAll("CDNote") }
    }

    // MARK: - Reading history

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd"
        return f
    }()

    /// One row per Bible + chapter per day: re-reading the same chapter updates
    /// that day's entry instead of adding another (Android: TrackingRepo.recordReading).
    func recordReading(_ entry: HistoryEntry) {
        context.performAndWait {
            let dayKey = Self.dayFormatter.string(from: entry.readAt)
            let existing: [CDHistory] = fetch(
                "CDHistory",
                predicate: NSPredicate(format: "bibleAbbr == %@ AND chapterId == %@ AND dayKey == %@", entry.bibleAbbr, entry.chapterId, dayKey),
                limit: 1
            )

            if let cd = existing.first {
                cd.bibleName = entry.bibleName
                cd.bookName = entry.bookName
                cd.chapterRef = entry.chapterRef
                if let verse = entry.verseNumber { cd.verseNumber = Int32(verse) }
            } else {
                let cd = CDHistory(context: context)
                cd.entryId = entry.id
                cd.bibleAbbr = entry.bibleAbbr
                cd.bibleName = entry.bibleName
                cd.bookId = entry.bookId
                cd.bookName = entry.bookName
                cd.chapterId = entry.chapterId
                cd.chapterRef = entry.chapterRef
                cd.verseNumber = Int32(entry.verseNumber ?? 0)
                cd.dayKey = dayKey
                cd.readAt = entry.readAt
                save()
                pruneHistory(keeping: 200)
                return
            }
            save()
        }
    }

    /// Must be called from inside `context.performAndWait`.
    private func pruneHistory(keeping limit: Int) {
        let all: [CDHistory] = fetch("CDHistory", sort: [NSSortDescriptor(key: "readAt", ascending: false)])
        guard all.count > limit else { return }
        all.dropFirst(limit).forEach { context.delete($0) }
        save()
    }

    func recentHistory(limit: Int = 100) -> [HistoryEntry] {
        context.performAndWait {
            let rows: [CDHistory] = fetch("CDHistory", sort: [NSSortDescriptor(key: "readAt", ascending: false)], limit: limit)
            return rows.map(MapCdToEntity.mapToEntity(_:))
        }
    }

    func clearHistory() {
        context.performAndWait { deleteAll("CDHistory") }
    }

    // MARK: - Searches

    func recordSearch(_ qry: String) {
        context.performAndWait {
            let dupes: [CDSearch] = fetch("CDSearch", predicate: NSPredicate(format: "qry ==[c] %@", qry))
            dupes.forEach { context.delete($0) }

            let cd = CDSearch(context: context)
            cd.searchId = UUID().uuidString
            cd.qry = qry
            cd.queriedAt = Date()
            save()

            let all: [CDSearch] = fetch("CDSearch", sort: [NSSortDescriptor(key: "queriedAt", ascending: false)])
            if all.count > 100 {
                all.dropFirst(100).forEach { context.delete($0) }
                save()
            }
        }
    }

    func recentSearches(limit: Int = 50) -> [SearchEntry] {
        context.performAndWait {
            let rows: [CDSearch] = fetch("CDSearch", sort: [NSSortDescriptor(key: "queriedAt", ascending: false)], limit: limit)
            return rows.map(MapCdToEntity.mapToEntity(_:))
        }
    }

    func clearSearches() {
        context.performAndWait { deleteAll("CDSearch") }
    }

    // MARK: - Scripture lists

    /// Saves a list and its items; the list is named after the first scripture
    /// unless `name` is given. Returns the new list id.
    func saveScriptureList(items: [ScriptureItem], name: String?) -> Int64 {
        context.performAndWait {
            let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let list = CDScriptureList(context: context)
            list.listId = nextId("CDScriptureList", key: "listId")
            list.name = trimmed.isEmpty ? (items.first?.reference ?? "Scripture List") : trimmed
            list.createdAt = Date()

            var itemId = nextId("CDScriptureItem", key: "itemId")
            for (index, item) in items.enumerated() {
                let cd = CDScriptureItem(context: context)
                cd.itemId = itemId
                itemId += 1
                cd.listId = list.listId
                cd.bibleAbbr = item.bibleAbbr
                cd.bibleName = item.bibleName
                cd.bookId = item.bookId
                cd.bookName = item.bookName
                cd.bookAbbr = item.bookAbbr
                cd.chapterId = item.chapterId
                cd.chapterNumber = item.chapterNumber
                cd.verseId = item.verseId
                cd.verseNumber = Int32(item.verseNumber)
                cd.reference = item.reference
                cd.sortOrder = Int32(index)
                cd.addedAt = Date()
            }
            let id = list.listId
            save()
            return id
        }
    }

    func allScriptureLists() -> [ScriptureList] {
        context.performAndWait {
            let rows: [CDScriptureList] = fetch("CDScriptureList", sort: [NSSortDescriptor(key: "createdAt", ascending: false)])
            return rows.map(MapCdToEntity.mapToEntity(_:))
        }
    }

    func scriptureList(id: Int64) -> ScriptureList? {
        context.performAndWait {
            let rows: [CDScriptureList] = fetch("CDScriptureList", predicate: NSPredicate(format: "listId == %lld", id), limit: 1)
            return rows.first.map(MapCdToEntity.mapToEntity(_:))
        }
    }

    func scriptureItems(listId: Int64) -> [ScriptureItem] {
        context.performAndWait {
            let rows: [CDScriptureItem] = fetch(
                "CDScriptureItem",
                predicate: NSPredicate(format: "listId == %lld", listId),
                sort: [NSSortDescriptor(key: "sortOrder", ascending: true)]
            )
            return rows.map(MapCdToEntity.mapToEntity(_:))
        }
    }

    func scriptureItemCount(listId: Int64) -> Int {
        context.performAndWait {
            let request = NSFetchRequest<CDScriptureItem>(entityName: "CDScriptureItem")
            request.predicate = NSPredicate(format: "listId == %lld", listId)
            return (try? context.count(for: request)) ?? 0
        }
    }

    func renameScriptureList(id: Int64, name: String) {
        context.performAndWait {
            let rows: [CDScriptureList] = fetch("CDScriptureList", predicate: NSPredicate(format: "listId == %lld", id), limit: 1)
            rows.first?.name = name
            save()
        }
    }

    func deleteScriptureList(id: Int64) {
        context.performAndWait {
            deleteAll("CDScriptureItem", predicate: NSPredicate(format: "listId == %lld", id))
            deleteAll("CDScriptureList", predicate: NSPredicate(format: "listId == %lld", id))
        }
    }

    // MARK: - Everything

    func deleteAllUserData() {
        context.performAndWait {
            for entity in ["CDBookmark", "CDNote", "CDHistory", "CDSearch", "CDScriptureItem", "CDScriptureList"] {
                deleteAll(entity)
            }
        }
    }
}
