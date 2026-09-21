//
//  SettingsViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

enum ClearTarget: Identifiable {
    case bookmarks, notes, history, searches, allData
    var id: Self { self }

    var title: String {
        switch self {
        case .bookmarks: return "Clear all bookmarks?"
        case .notes: return "Clear all notes?"
        case .history: return "Clear all history?"
        case .searches: return "Clear search history?"
        case .allData: return "Clear ALL app data?"
        }
    }

    var message: String {
        switch self {
        case .bookmarks: return "This permanently deletes every bookmark across all your Bibles. This can't be undone."
        case .notes: return "This permanently deletes every note across all your Bibles. This can't be undone."
        case .history: return "This permanently deletes your reading history. This can't be undone."
        case .searches: return "This permanently deletes your recent searches. This can't be undone."
        case .allData:
            return "This deletes everything — downloaded Bibles, bookmarks, notes, history, searches, and preferences — and restarts the app at Bible selection. This cannot be undone."
        }
    }
}

final class SettingsViewModel: ObservableObject {
    @Published var pendingClear: ClearTarget?

    private let prefsRepo: PrefsRepo
    private let bibleRepo: BibleRepoProtocol
    private let annotationRepo: AnnotationRepo
    private let trackingRepo: TrackingRepo
    private let scriptureRepo: ScriptureRepo
    private let syncScheduler: SyncScheduler

    init(
        prefsRepo: PrefsRepo,
        bibleRepo: BibleRepoProtocol,
        annotationRepo: AnnotationRepo,
        trackingRepo: TrackingRepo,
        scriptureRepo: ScriptureRepo,
        syncScheduler: SyncScheduler
    ) {
        self.prefsRepo = prefsRepo
        self.bibleRepo = bibleRepo
        self.annotationRepo = annotationRepo
        self.trackingRepo = trackingRepo
        self.scriptureRepo = scriptureRepo
        self.syncScheduler = syncScheduler
    }

    /// Returns true when everything was wiped and the app should restart at Bible selection.
    @discardableResult
    func confirmClear() -> Bool {
        guard let target = pendingClear else { return false }
        pendingClear = nil

        switch target {
        case .bookmarks:
            annotationRepo.deleteBookmarks(annotationRepo.allBookmarks())
        case .notes:
            annotationRepo.deleteNotes(annotationRepo.allNotes())
        case .history:
            trackingRepo.clearHistory()
        case .searches:
            trackingRepo.clearSearchHistory()
        case .allData:
            syncScheduler.cancelAll()
            annotationRepo.clearAllBookmarksAndNotes()
            trackingRepo.clearHistory()
            trackingRepo.clearSearchHistory()
            scriptureRepo.allLists().forEach { scriptureRepo.deleteList(id: $0.id) }
            bibleRepo.deleteAllData()
            prefsRepo.resetPrefs()
            return true
        }
        return false
    }
}
