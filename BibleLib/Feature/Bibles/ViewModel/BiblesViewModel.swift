//
//  BiblesViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

final class BiblesViewModel: ObservableObject {
    @Published private(set) var bibles: [Bible] = []
    @Published private(set) var primaryAbbr = ""
    @Published private(set) var secondaryBibles: [String] = []
    @Published private(set) var isLoading = true
    @Published var multiBibleEnabled = true
    @Published var pendingDelete: Bible?
    @Published var showManagementInfo = false
    @Published var showFirstOpenPrompt = false

    private let bibleRepo: BibleRepoProtocol
    private let prefsRepo: PrefsRepo
    private let syncScheduler: SyncScheduler

    init(bibleRepo: BibleRepoProtocol, prefsRepo: PrefsRepo, syncScheduler: SyncScheduler) {
        self.bibleRepo = bibleRepo
        self.prefsRepo = prefsRepo
        self.syncScheduler = syncScheduler
    }

    var primary: Bible? { bibles.first { $0.abbreviation == primaryAbbr } }

    var secondary: [Bible] {
        secondaryBibles.compactMap { abbr in bibles.first { $0.abbreviation == abbr } }
    }

    /// Everything that isn't the primary or a secondary Bible.
    var others: [Bible] {
        bibles.filter { $0.abbreviation != primaryAbbr && !secondaryBibles.contains($0.abbreviation) }
    }

    var hasPendingDownloads: Bool {
        bibles.contains { !$0.isDownloaded && !$0.downloadFailed }
    }

    func load() {
        let all = bibleRepo.localBibles().sorted { $0.sortOrder < $1.sortOrder }
        let primary = prefsRepo.primaryBibleAbbr ?? ""
        let owned = Set(all.map(\.abbreviation))

        var secondary = prefsRepo.secondaryBibles.filter { owned.contains($0) && $0 != primary }
        if secondary.isEmpty {
            secondary = all.filter { $0.abbreviation != primary }
                .prefix(MultiBibleLimits.defaultSecondary)
                .map(\.abbreviation)
        }
        prefsRepo.secondaryBibles = secondary

        bibles = all
        primaryAbbr = primary
        secondaryBibles = secondary
        multiBibleEnabled = prefsRepo.multiBibleReaderEnabled
        showFirstOpenPrompt = !prefsRepo.hasSeenBiblesManagementTip
        isLoading = false
    }

    func retryDownload(_ abbr: String) {
        syncScheduler.retryDownload(abbr)
        load()
    }

    func restartDownload(_ abbr: String) {
        syncScheduler.restartDownload(abbr)
        load()
    }

    func setPrimaryBible(_ abbr: String) {
        guard let bible = bibles.first(where: { $0.abbreviation == abbr }), bible.isDownloaded else { return }
        prefsRepo.primaryBibleAbbr = abbr
        prefsRepo.lastBibleAbbr = abbr
        prefsRepo.lastBible = bible.name
        prefsRepo.lastBookId = ""
        prefsRepo.lastChapterId = ""
        prefsRepo.lastVerseId = ""
        prefsRepo.secondaryBibles = prefsRepo.secondaryBibles.filter { $0 != abbr }
        load()
    }

    // MARK: - Delete

    func confirmDelete() {
        guard let bible = pendingDelete else { return }
        syncScheduler.cancelDownload(bible.abbreviation)
        bibleRepo.deleteBible(abbr: bible.abbreviation)

        let remaining = prefsRepo.selectedBibles.filter { $0 != bible.abbreviation }
        prefsRepo.selectedBibles = remaining
        prefsRepo.secondaryBibles = prefsRepo.secondaryBibles.filter { $0 != bible.abbreviation }
        if prefsRepo.primaryBibleAbbr == bible.abbreviation {
            prefsRepo.primaryBibleAbbr = remaining.first
            prefsRepo.lastBibleAbbr = ""
            prefsRepo.lastBookId = ""
            prefsRepo.lastChapterId = ""
            prefsRepo.lastVerseId = ""
        }
        pendingDelete = nil
        load()
    }

    func setMultiBibleEnabled(_ enabled: Bool) {
        prefsRepo.multiBibleReaderEnabled = enabled
        multiBibleEnabled = enabled
    }

    @discardableResult
    func toggleSecondary(_ abbr: String) -> Bool {
        var updated = secondaryBibles
        if let index = updated.firstIndex(of: abbr) {
            updated.remove(at: index)
        } else {
            guard updated.count < MultiBibleLimits.maxSecondary else { return false }
            updated.append(abbr)
        }
        secondaryBibles = updated
        prefsRepo.secondaryBibles = updated
        return true
    }

    func moveSecondary(from source: IndexSet, to destination: Int) {
        var updated = secondaryBibles
        updated.move(fromOffsets: source, toOffset: destination)
        secondaryBibles = updated
        prefsRepo.secondaryBibles = updated
    }

    func dismissFirstOpenPrompt(showInfoNext: Bool) {
        prefsRepo.hasSeenBiblesManagementTip = true
        showFirstOpenPrompt = false
        showManagementInfo = showInfoNext
    }
}
