//
//  SelectionViewModel.swift
//  BibleLib
//
//  Port of Android's SelectionViewModel plus its FirstTimeSelectionController /
//  ReturningSelectionController / persistSelectionBookkeeping:
//
//  - First install: the primary Bible (the first one selected, in list order)
//    downloads in the foreground with visible progress; the rest are queued in
//    the background once it succeeds.
//  - Returning user re-selecting: everything is queued in the background and the
//    screen closes immediately.
//

import Foundation

final class SelectionViewModel: ObservableObject {
    static let firstInstallMax = 7
    static let additionalBiblesAllowed = 5

    @Published var uiState: UiState = .loading(nil)
    @Published var bibles: [Selectable<BibleInfoDTO>] = []
    @Published var groupingMode: GroupingMode = .default
    @Published var maxSelections = SelectionViewModel.firstInstallMax
    @Published var downloadProgress: Double = 0
    @Published var downloadStep = "Preparing ..."

    /// The Bible the Reader should open once the selection has been saved.
    private(set) var savedPrimaryAbbr: String?

    private let bibleRepo: BibleRepoProtocol
    private let prefsRepo: PrefsRepo
    private let syncScheduler: SyncScheduler

    private var pendingSelection: [BibleInfoDTO] = []

    init(bibleRepo: BibleRepoProtocol, prefsRepo: PrefsRepo, syncScheduler: SyncScheduler) {
        self.bibleRepo = bibleRepo
        self.prefsRepo = prefsRepo
        self.syncScheduler = syncScheduler
    }

    var isFirstInstall: Bool { !prefsRepo.hasCompletedSelection }

    var selectedCount: Int { bibles.filter(\.isSelected).count }

    var canProceed: Bool { selectedCount > 0 }

    // MARK: - Loading

    /// Also the Refresh action: reloads the list and drops any unsaved picks,
    /// restoring the previously saved selection (as Android does).
    func fetchBibles() {
        uiState = .loading(nil)

        Task { @MainActor in
            do {
                let selected = Set(prefsRepo.selectedBibles)

                maxSelections = isFirstInstall
                    ? Self.firstInstallMax
                    : Self.firstInstallMax + Self.additionalBiblesAllowed

                let dtos = try await bibleRepo.fetchAvailableBibles()
                bibles = dtos.map {
                    Selectable(data: $0, isSelected: selected.contains($0.abbreviation))
                }
                prefsRepo.isDataLoaded = true
                uiState = .loaded
            } catch {
                print("SelectionViewModel.fetchBibles failed: \(error)")
                uiState = .error("Could not load Bibles. Please check your connection and try again.")
            }
        }
    }

    func setGroupingMode(_ mode: GroupingMode) {
        groupingMode = mode
    }

    func toggleSelection(_ abbr: String) {
        guard let index = bibles.firstIndex(where: { $0.data.abbreviation == abbr }) else { return }

        let shouldSelect = !bibles[index].isSelected
        if shouldSelect && selectedCount >= maxSelections { return }

        bibles[index].isSelected = shouldSelect
    }

    private func currentSelection() -> [BibleInfoDTO] {
        bibles.filter(\.isSelected).map(\.data)
    }

    // MARK: - First-install flow

    func saveSelectionAndDownload() {
        let selected = currentSelection()
        guard !selected.isEmpty else { return }
        pendingSelection = selected

        uiState = .saving(nil)
        downloadProgress = 0
        downloadStep = "Preparing..."

        Task { @MainActor in
            do {
                persistSelectionBookkeeping(selected)
                try await downloadPrimaryAndQueueSecondaries(selected)
                uiState = .saved
            } catch {
                print("SelectionViewModel.saveSelectionAndDownload failed: \(error)")
                uiState = .saveFailed(
                    message: "Failed to download the Bible. You can continue where it left off or restart.",
                    progress: downloadProgress
                )
            }
        }
    }

    func continuePrimaryDownload() {
        let selected = pendingSelection
        guard let primary = selected.first else { return }

        uiState = .saving(nil)
        downloadStep = "Resuming download..."

        Task { @MainActor in
            do {
                downloadProgress = bibleRepo.localBibles()
                    .first { $0.abbreviation == primary.abbreviation }?
                    .downloadProgress ?? 0

                try await downloadPrimaryAndQueueSecondaries(selected)
                uiState = .saved
            } catch {
                print("SelectionViewModel.continuePrimaryDownload failed: \(error)")
                uiState = .saveFailed(
                    message: "Still couldn't finish the download. You can continue or restart.",
                    progress: downloadProgress
                )
            }
        }
    }

    func restartPrimaryDownload() {
        let selected = pendingSelection
        guard let primary = selected.first else { return }

        uiState = .saving(nil)
        downloadProgress = 0
        downloadStep = "Restarting download..."

        Task { @MainActor in
            do {
                bibleRepo.clearBibleContent(abbr: primary.abbreviation)
                try await downloadPrimaryAndQueueSecondaries(selected)
                uiState = .saved
            } catch {
                print("SelectionViewModel.restartPrimaryDownload failed: \(error)")
                uiState = .saveFailed(
                    message: "Failed to download the Bible. You can continue where it left off or restart.",
                    progress: downloadProgress
                )
            }
        }
    }

    @MainActor
    private func downloadPrimaryAndQueueSecondaries(_ selected: [BibleInfoDTO]) async throws {
        guard let primary = selected.first else { return }

        if !bibleRepo.localBibles().contains(where: { $0.abbreviation == primary.abbreviation }) {
            persistSelectionBookkeeping(selected)
        }

        try await bibleRepo.downloadBible(abbr: primary.abbreviation) { [weak self] step, progress in
            Task { @MainActor in
                self?.downloadStep = step
                self?.downloadProgress = progress
            }
        }

        // Only now is the app usable: Splash routes to the Reader on this flag.
        prefsRepo.hasCompletedSelection = true

        syncScheduler.scheduleDownloads(selected.dropFirst().map(\.abbreviation))
    }

    // MARK: - Returning-user reselection

    func saveSelectionInBackground() {
        let selected = currentSelection()
        guard !selected.isEmpty else { return }

        persistSelectionBookkeeping(selected)
        prefsRepo.hasCompletedSelection = true
        syncScheduler.scheduleDownloads(selected.map(\.abbreviation))
        uiState = .saved
    }

    // MARK: - Bookkeeping

    /// Mirrors Android's `persistSelectionBookkeeping`: drops Bibles that are no
    /// longer selected, records the new selection and primary, and upserts the
    /// selected Bibles' metadata.
    private func persistSelectionBookkeeping(_ selected: [BibleInfoDTO]) {
        guard let primary = selected.first else { return }
        let newAbbrs = Set(selected.map(\.abbreviation))

        for abbr in prefsRepo.selectedBibles where !newAbbrs.contains(abbr) {
            syncScheduler.cancelDownload(abbr)
            bibleRepo.deleteBible(abbr: abbr)
        }

        prefsRepo.selectedBibles = selected.map(\.abbreviation)
        prefsRepo.primaryBibleAbbr = primary.abbreviation
        savedPrimaryAbbr = primary.abbreviation

        bibleRepo.saveBibles(
            selected.enumerated().map { index, dto in
                Bible(
                    abbreviation: dto.abbreviation,
                    name: dto.name,
                    description: dto.description,
                    languageName: dto.language.name,
                    scriptDirection: dto.language.scriptDirection,
                    sortOrder: index,
                    isDownloaded: false,
                    countryName: dto.primaryCountryName(),
                    downloadProgress: 0,
                    downloadFailed: false,
                    path: dto.path
                )
            }
        )
    }
}
