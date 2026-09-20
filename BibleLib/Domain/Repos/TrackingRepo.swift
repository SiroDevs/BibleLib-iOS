//
//  TrackingRepo.swift
//  BibleLib
//
//  Reading history and recent searches (Android: TrackingRepo).
//

import Foundation

final class TrackingRepo {
    private let data: UserDataManager

    init(data: UserDataManager) {
        self.data = data
    }

    func recordReading(_ entry: HistoryEntry) { data.recordReading(entry) }
    func readingHistory() -> [HistoryEntry] { data.recentHistory() }
    func clearHistory() { data.clearHistory() }

    func recordSearch(_ qry: String) { data.recordSearch(qry) }
    func searchHistory() -> [SearchEntry] { data.recentSearches() }
    func clearSearchHistory() { data.clearSearches() }
}
