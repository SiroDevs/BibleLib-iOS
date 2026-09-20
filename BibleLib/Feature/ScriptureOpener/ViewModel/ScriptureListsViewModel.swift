//
//  ScriptureListsViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

struct ScriptureListSummary: Identifiable {
    let list: ScriptureList
    let itemCount: Int
    let firstReference: String
    var id: Int64 { list.id }
}

final class ScriptureListsViewModel: ObservableObject {
    @Published private(set) var lists: [ScriptureListSummary] = []
    @Published private(set) var isLoading = true

    private let scriptureRepo: ScriptureRepo

    init(scriptureRepo: ScriptureRepo) {
        self.scriptureRepo = scriptureRepo
    }

    func load() {
        lists = scriptureRepo.allLists().map { list in
            let items = scriptureRepo.items(listId: list.id)
            return ScriptureListSummary(list: list, itemCount: items.count, firstReference: items.first?.reference ?? "")
        }
        isLoading = false
    }

    func rename(_ id: Int64, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        scriptureRepo.renameList(id: id, name: trimmed)
        load()
    }

    func delete(_ id: Int64) {
        scriptureRepo.deleteList(id: id)
        load()
    }
}

final class ScriptureListDetailViewModel: ObservableObject {
    @Published private(set) var list: ScriptureList?
    @Published private(set) var items: [ScriptureItem] = []
    @Published private(set) var isLoading = true
    @Published private(set) var deleted = false

    private let scriptureRepo: ScriptureRepo
    private let queueRepo: ScriptureQueueRepo
    private var listId: Int64?

    init(scriptureRepo: ScriptureRepo, queueRepo: ScriptureQueueRepo) {
        self.scriptureRepo = scriptureRepo
        self.queueRepo = queueRepo
    }

    func load(id: Int64) {
        listId = id
        list = scriptureRepo.list(id: id)
        items = scriptureRepo.items(listId: id)
        isLoading = false
    }

    func rename(to name: String) {
        guard let listId else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        scriptureRepo.renameList(id: listId, name: trimmed)
        load(id: listId)
    }

    func delete() {
        guard let listId else { return }
        scriptureRepo.deleteList(id: listId)
        deleted = true
    }
    
    func open(startingAt item: ScriptureItem? = nil) -> ReaderTarget? {
        guard let list, let start = item ?? items.first else { return nil }
        queueRepo.open(listId: list.id, listName: list.name, items: items, activeItemId: start.id)
        return ReaderTarget(
            bibleAbbr: start.bibleAbbr,
            bookId: start.bookId,
            chapterId: start.chapterId,
            verseId: start.verseId
        )
    }
}
