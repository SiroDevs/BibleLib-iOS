//
//  SelectionViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

final class SelectionViewModel: ObservableObject {
    @Published var bibles: [Selectable<Bible>] = []
    @Published var uiState: UiState = .idle
    @Published var primaryAbbr: String?
    @Published var downloadProgress: [String: (step: String, value: Double)] = [:]
    @Published var isDownloading = false

    private let bibleRepo: BibleRepoProtocol
    private let prefsRepo: PrefsRepo

    init(bibleRepo: BibleRepoProtocol, prefsRepo: PrefsRepo) {
        self.bibleRepo = bibleRepo
        self.prefsRepo = prefsRepo
    }

    @MainActor
    func loadAvailableBibles() async {
        uiState = .loading("Loading Bibles…")
        do {
            let dtos = try await bibleRepo.fetchAvailableBibles()
            let entities = dtos.enumerated().map { index, dto in
                Bible(
                    abbreviation: dto.abbreviation,
                    name: dto.name,
                    description: dto.description,
                    languageName: dto.language.name,
                    scriptDirection: dto.language.scriptDirection,
                    sortOrder: index,
                    isDownloaded: false,
                    countryName: dto.countries.first?.name ?? "",
                    downloadProgress: 0,
                    downloadFailed: false
                )
            }
            bibleRepo.saveBibles(entities)
            prefsRepo.isDataLoaded = true
            refreshFromLocal()
            uiState = .loaded
        } catch {
            uiState = .error("Couldn't load the list of Bibles. Check your connection and try again.")
        }
    }

    @MainActor
    private func refreshFromLocal() {
        let local = bibleRepo.localBibles()
        bibles = local.map { Selectable(data: $0, isSelected: $0.abbreviation == primaryAbbr) }
        if primaryAbbr == nil {
            primaryAbbr = local.first?.abbreviation
        }
    }

    func toggleSelection(_ abbr: String) {
        guard let index = bibles.firstIndex(where: { $0.data.abbreviation == abbr }) else { return }
        bibles[index].isSelected.toggle()
        if !bibles[index].isSelected, primaryAbbr == abbr {
            primaryAbbr = bibles.first(where: \.isSelected)?.data.abbreviation
        }
    }

    func setPrimary(_ abbr: String) {
        primaryAbbr = abbr
        guard let index = bibles.firstIndex(where: { $0.data.abbreviation == abbr }) else { return }
        if !bibles[index].isSelected {
            bibles[index].isSelected = true
        }
    }

    @MainActor
    func downloadSelected() async {
        guard !isDownloading else { return }
        let selected = bibles.filter(\.isSelected).map(\.data.abbreviation)
        guard !selected.isEmpty else { return }
        if primaryAbbr == nil || !selected.contains(primaryAbbr!) {
            primaryAbbr = selected.first
        }

        isDownloading = true
        defer { isDownloading = false }

        uiState = .loading("Downloading…")
        for abbr in selected {
            do {
                try await bibleRepo.downloadBible(abbr: abbr) { [weak self] step, progress in
                    Task { @MainActor in
                        self?.downloadProgress[abbr] = (step, progress)
                    }
                }
            } catch {
                uiState = .error("Failed to download \(abbr). Check your connection and try again.")
                return
            }
        }

        prefsRepo.primaryBibleAbbr = primaryAbbr
        prefsRepo.hasCompletedSelection = true
        uiState = .saved
    }
}
