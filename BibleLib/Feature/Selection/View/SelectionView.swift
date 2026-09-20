//
//  SelectionView.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

struct SelectionView: View {
    @StateObject private var viewModel: SelectionViewModel = DiContainer.shared.resolve(SelectionViewModel.self)
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let onFinished: (String) -> Void
    let onCancel: (() -> Void)?

    init(onFinished: @escaping (String) -> Void = { _ in }, onCancel: (() -> Void)? = nil) {
        self.onFinished = onFinished
        self.onCancel = onCancel
    }

    @State private var showThemeDialog = false
    @State private var expandedGroups: [String: Bool] = [:]
    @State private var countryFilters: [String: String] = [:]

    private var showChrome: Bool {
        switch viewModel.uiState {
        case .saving, .saveFailed: return false
        default: return true
        }
    }

    private var isLoaded: Bool {
        if case .loaded = viewModel.uiState { return true }
        return false
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottomTrailing) {
                        if !viewModel.isFirstInstall && isLoaded {
                            cancelButton
                        }
                    }

                if isLoaded {
                    ProceedBar(canProceed: viewModel.canProceed) {
                        if viewModel.isFirstInstall {
                            viewModel.saveSelectionAndDownload()
                        } else {
                            viewModel.saveSelectionInBackground()
                        }
                    }
                }
            }
            .background(AppColors.background.ignoresSafeArea())

            if showThemeDialog {
                ThemeSelectorDialog(
                    current: themeManager.selectedTheme,
                    onDismiss: { showThemeDialog = false },
                    onThemeSelected: { themeManager.selectedTheme = $0 }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showThemeDialog)
        .task { viewModel.fetchBibles() }
        .onChange(of: viewModel.uiState) { state in
            if case .saved = state, let abbr = viewModel.savedPrimaryAbbr {
                onFinished(abbr)
            }
        }
    }

    @ViewBuilder
    private var topBar: some View {
        if showChrome {
            AppTopBar(
                title: "BibleLib: Multi-Bible Reader",
                tagline: "\(viewModel.selectedCount) / \(viewModel.maxSelections) bibles selected"
            ) {
                AppIconButton(systemName: "arrow.clockwise", accessibilityLabel: "Refresh") {
                    viewModel.fetchBibles()
                }
                AppIconButton(systemName: "circle.lefthalf.filled", accessibilityLabel: "Theme") {
                    showThemeDialog = true
                }
            }
        } else {
            AppTopBar(title: "BibleLib: Multi-Bible Reader")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.uiState {
        case .loading:
            BibleCardShimmer()

        case .error(let message):
            RetryErrorState(message: message) { viewModel.fetchBibles() }

        case .saving:
            BibleSavingProgress(progress: viewModel.downloadProgress, step: viewModel.downloadStep)

        case .saveFailed(let message, let progress):
            DownloadFailedState(
                message: message,
                progress: progress,
                onContinue: { viewModel.continuePrimaryDownload() },
                onRestart: { viewModel.restartPrimaryDownload() }
            )

        default:
            VStack(spacing: 0) {
                GroupingFilmStrip(selected: viewModel.groupingMode) {
                    viewModel.setGroupingMode($0)
                }
                grid
            }
        }
    }

    private enum GridLine: Identifiable {
        case header(GridEntry, key: String, title: String, total: Int)
        case filter(GridEntry, continentKey: String, options: [FilterOption], selected: String)
        case items([GridEntry])
        case solo(GridEntry)

        var id: String {
            switch self {
            case .header(let entry, _, _, _): return entry.id
            case .filter(let entry, _, _, _): return entry.id
            case .items(let entries): return entries.first?.id ?? "items"
            case .solo(let entry): return entry.id
            }
        }
    }

    private func gridLines(from entries: [GridEntry]) -> [GridLine] {
        var lines: [GridLine] = []
        var pending: [GridEntry] = []

        func flush() {
            var index = 0
            while index < pending.count {
                lines.append(.items(Array(pending[index..<min(index + 2, pending.count)])))
                index += 2
            }
            pending.removeAll()
        }

        for entry in entries {
            switch entry {
            case .header(let key, let title, let total):
                flush()
                lines.append(.header(entry, key: key, title: title, total: total))
            case .countryFilterStrip(_, let continentKey, let options, let selected):
                flush()
                lines.append(.filter(entry, continentKey: continentKey, options: options, selected: selected))
            case .item(_, _, let solo):
                if solo {
                    flush()
                    lines.append(.solo(entry))
                } else {
                    pending.append(entry)
                }
            }
        }
        flush()
        return lines
    }

    private var grid: some View {
        let entries = buildGridEntries(
            bibles: viewModel.bibles,
            mode: viewModel.groupingMode,
            expandedGroups: expandedGroups,
            countryFilters: countryFilters
        )

        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(gridLines(from: entries)) { line in
                    lineView(line)
                }
            }
            .padding(2)
        }
    }

    @ViewBuilder
    private func lineView(_ line: GridLine) -> some View {
        switch line {
        case .header(_, let key, let title, let total):
            let isExpanded = expandedGroups[key] ?? true
            GroupHeader(title: title, totalInGroup: total, expanded: isExpanded) {
                expandedGroups[key] = !isExpanded
            }

        case .filter(_, let continentKey, let options, let selected):
            FilterChipStrip(options: options, selected: selected) { country in
                countryFilters[continentKey] = country
            }

        case .solo(let entry):
            card(for: entry)

        case .items(let entries):
            HStack(alignment: .top, spacing: 0) {
                card(for: entries[0])
                if entries.count > 1 {
                    card(for: entries[1])
                } else {
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func card(for entry: GridEntry) -> some View {
        if case .item(_, let bible, _) = entry {
            BibleListItem(
                name: bible.data.name,
                description: bible.data.description,
                abbreviation: bible.data.abbreviation,
                language: bible.data.language.name,
                isSelected: bible.isSelected,
                isDisabled: !bible.isSelected && viewModel.selectedCount >= viewModel.maxSelections,
                onClick: { viewModel.toggleSelection(bible.data.abbreviation) }
            )
            .padding(2)
        }
    }

    private var cancelButton: some View {
        Button {
            if let onCancel { onCancel() } else { dismiss() }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppColors.onPrimaryContainer)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.primaryContainer))
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel selection")
        .padding(16)
    }
}

#Preview {
    SelectionView()
        .environmentObject(ThemeManager())
}
