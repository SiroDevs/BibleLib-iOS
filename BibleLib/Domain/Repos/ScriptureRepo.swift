//
//  ScriptureRepo.swift
//  BibleLib
//
//  Saved scripture lists (Android: ScriptureRepo) and the in-memory reading queue
//  the reader shows while a list is open (Android: ScriptureQueueRepo).
//

import Foundation

final class ScriptureRepo {
    private let data: UserDataManager

    init(data: UserDataManager) {
        self.data = data
    }

    func saveList(items: [ScriptureItem], name: String? = nil) -> Int64 {
        data.saveScriptureList(items: items, name: name)
    }

    func allLists() -> [ScriptureList] { data.allScriptureLists() }
    func list(id: Int64) -> ScriptureList? { data.scriptureList(id: id) }
    func items(listId: Int64) -> [ScriptureItem] { data.scriptureItems(listId: listId) }
    func itemCount(listId: Int64) -> Int { data.scriptureItemCount(listId: listId) }
    func renameList(id: Int64, name: String) { data.renameScriptureList(id: id, name: name) }
    func deleteList(id: Int64) { data.deleteScriptureList(id: id) }
}

/// The scripture list currently "open" in the reader. Observable so the reader's
/// queue bar updates as soon as the opener or a saved list fills it.
final class ScriptureQueueRepo: ObservableObject {
    @Published private(set) var listId: Int64?
    @Published private(set) var listName = ""
    @Published private(set) var items: [ScriptureItem] = []
    @Published private(set) var activeItemId: Int64?

    var isOpen: Bool { !items.isEmpty }

    func open(listId: Int64, listName: String, items: [ScriptureItem], activeItemId: Int64? = nil) {
        self.listId = listId
        self.listName = listName
        self.items = items
        self.activeItemId = activeItemId ?? items.first?.id
    }

    func setActiveItem(_ itemId: Int64) {
        if items.contains(where: { $0.id == itemId }) { activeItemId = itemId }
    }

    func syncActiveByChapter(bibleAbbr: String, chapterId: String) {
        if let match = items.first(where: { $0.bibleAbbr == bibleAbbr && $0.chapterId == chapterId }) {
            activeItemId = match.id
        }
    }

    func dismiss() {
        listId = nil
        listName = ""
        items = []
        activeItemId = nil
    }
}
