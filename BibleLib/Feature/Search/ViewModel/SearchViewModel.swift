//
//  SearchViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [VerseDisplay] = []
    @Published private(set) var isSearching = false
    @Published private(set) var searchHistory: [SearchEntry] = []
    @Published private(set) var bibles: [Bible] = []
    @Published private(set) var selectedBibleAbbr = ""
    @Published private(set) var bookNames: [String: String] = [:]
    @Published private(set) var searchedQuery = ""

    private let bibleRepo: BibleRepoProtocol
    private let prefsRepo: PrefsRepo
    private let trackingRepo: TrackingRepo
    private var searchTask: Task<Void, Never>?

    private static let minimumQueryLength = 3

    init(bibleRepo: BibleRepoProtocol, prefsRepo: PrefsRepo, trackingRepo: TrackingRepo) {
        self.bibleRepo = bibleRepo
        self.prefsRepo = prefsRepo
        self.trackingRepo = trackingRepo
    }

    func load() {
        guard bibles.isEmpty else { return }
        let downloaded = bibleRepo.localBibles().filter(\.isDownloaded)
        bibles = downloaded
        let primary = prefsRepo.primaryBibleAbbr ?? ""
        selectedBibleAbbr = downloaded.contains { $0.abbreviation == primary } ? primary : (downloaded.first?.abbreviation ?? "")
        loadBookNames()
        searchHistory = trackingRepo.searchHistory()
    }

    private func loadBookNames() {
        bookNames = selectedBibleAbbr.isEmpty
            ? [:]
            : Dictionary(bibleRepo.localBooks(abbr: selectedBibleAbbr).map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    func queryChanged() {
        searchTask?.cancel()
        let current = query.trimmingCharacters(in: .whitespaces)
        guard current.count >= Self.minimumQueryLength else {
            results = []
            searchedQuery = ""
            isSearching = false
            return
        }
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(current)
        }
    }

    func selectBible(_ abbr: String) {
        guard abbr != selectedBibleAbbr else { return }
        selectedBibleAbbr = abbr
        loadBookNames()
        let current = query.trimmingCharacters(in: .whitespaces)
        if current.count >= Self.minimumQueryLength {
            searchTask?.cancel()
            searchTask = Task { @MainActor in await performSearch(current) }
        }
    }

    func searchFromHistory(_ entry: SearchEntry) {
        query = entry.qry
        searchTask?.cancel()
        searchTask = Task { @MainActor in await performSearch(entry.qry) }
    }

    func clearQuery() {
        searchTask?.cancel()
        query = ""
        results = []
        searchedQuery = ""
    }

    func clearSearchHistory() {
        trackingRepo.clearSearchHistory()
        searchHistory = []
    }

    @MainActor
    private func performSearch(_ text: String) async {
        isSearching = true
        let abbr = selectedBibleAbbr.nonEmpty ?? (prefsRepo.primaryBibleAbbr ?? "")
        let repo = bibleRepo

        let found = await Task.detached(priority: .userInitiated) {
            repo.searchVerses(abbr: abbr, query: text)
        }.value

        guard !Task.isCancelled else { return }
        results = found
        searchedQuery = text
        isSearching = false

        if !found.isEmpty {
            trackingRepo.recordSearch(text)
            searchHistory = trackingRepo.searchHistory()
        }
    }
}
