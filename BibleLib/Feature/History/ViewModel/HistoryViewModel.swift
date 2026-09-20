//
//  HistoryViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

struct HistoryDay: Identifiable {
    let dayKey: String
    let title: String
    let entries: [HistoryEntry]
    var id: String { dayKey }
}

final class HistoryViewModel: ObservableObject {
    @Published private(set) var days: [HistoryDay] = []
    @Published private(set) var isLoading = true

    private let trackingRepo: TrackingRepo

    init(trackingRepo: TrackingRepo) {
        self.trackingRepo = trackingRepo
    }

    func load() {
        let entries = trackingRepo.readingHistory()
        let grouped = Dictionary(grouping: entries, by: \.dayKey)
        days = grouped
            .map { key, items in
                let sorted = items.sorted { $0.readAt > $1.readAt }
                return HistoryDay(dayKey: key, title: Self.title(for: sorted[0].readAt), entries: sorted)
            }
            .sorted { ($0.entries.first?.readAt ?? .distantPast) > ($1.entries.first?.readAt ?? .distantPast) }
        isLoading = false
    }

    func clear() {
        trackingRepo.clearHistory()
        load()
    }

    private static func title(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .complete, time: .omitted)
    }
}
