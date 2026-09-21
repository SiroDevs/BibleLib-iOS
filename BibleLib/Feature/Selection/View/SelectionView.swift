//
//  SelectionView.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct SelectionView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(SelectionViewModel.self)
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let onFinished: (String) -> Void
    let onCancel: (() -> Void)?

    @State private var showThemes = false
    @State private var expandedGroups: [String: Bool] = [:]
    @State private var countryFilters: [String: String] = [:]

    init(onFinished: @escaping (String) -> Void = { _ in }, onCancel: (() -> Void)? = nil) {
        self.onFinished = onFinished
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("BibleLib: Multi-Bible Reader")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .safeAreaInset(edge: .bottom, spacing: 0) { continueBar }
        }
        .sheet(isPresented: $showThemes) { ThemeSelectorSheet() }
        .task { viewModel.fetchBibles() }
        .onChange(of: viewModel.uiState) { state in
            if case .saved = state, let abbr = viewModel.savedPrimaryAbbr { onFinished(abbr) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.uiState {
        case .loading:
            List(0..<8, id: \.self) { _ in
                BibleItemPlaceholder()
            }
            .listStyle(.insetGrouped)
            .disabled(true)
        case .error(let message):
            ErrorState(message: message) { viewModel.fetchBibles() }
        case .saving:
            SavingProgressView(progress: viewModel.downloadProgress, step: viewModel.downloadStep)
        case .saveFailed(let message, let progress):
            DownloadFailedView(
                message: message,
                progress: progress,
                onRestart: viewModel.restartPrimaryDownload,
                onContinue: viewModel.continuePrimaryDownload
            )
        default:
            VStack(spacing: 0) {
                groupingPicker
                biblesList
            }
        }
    }

    private var groupingPicker: some View {
        Picker("Group by", selection: Binding(
            get: { viewModel.groupingMode },
            set: viewModel.setGroupingMode
        )) {
            ForEach(GroupingMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var biblesList: some View {
        let entries = buildGridEntries(
            bibles: viewModel.bibles,
            mode: viewModel.groupingMode,
            expandedGroups: expandedGroups,
            countryFilters: countryFilters
        )

        return List {
            ForEach(SelectionSection.make(from: entries)) { section in
                Section {
                    if let filter = section.filter { countryPicker(filter) }
                    ForEach(section.items, id: \.data.abbreviation) { bible in
                        BibleItem(
                            bible: bible.data,
                            isSelected: bible.isSelected,
                            isDisabled: !bible.isSelected && viewModel.selectedCount >= viewModel.maxSelections
                        ) {
                            viewModel.toggleSelection(bible.data.abbreviation)
                        }
                    }
                } header: {
                    if let header = section.header { groupHeader(header) }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func groupHeader(_ header: SelectionSection.Header) -> some View {
        let isExpanded = expandedGroups[header.key] ?? true

        return Button {
            withAnimation { expandedGroups[header.key] = !isExpanded }
        } label: {
            HStack {
                Text(header.title).font(.headline).foregroundStyle(.primary)
                Text(header.total == 1 ? "1 bible" : "\(header.total) bibles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .textCase(nil)
        }
    }

    private func countryPicker(_ filter: SelectionSection.CountryFilter) -> some View {
        Picker("Country", selection: Binding(
            get: { filter.selected },
            set: { countryFilters[filter.continentKey] = $0 }
        )) {
            ForEach(filter.options, id: \.name) { option in
                Text("\(option.name) (\(option.count))").tag(option.name)
            }
        }
        .pickerStyle(.menu)
    }

    private var showsChrome: Bool {
        switch viewModel.uiState {
        case .saving, .saveFailed: return false
        default: return true
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if !viewModel.isFirstInstall && showsChrome {
                Button("Cancel") { if let onCancel { onCancel() } else { dismiss() } }
            }
        }

        ToolbarItem(placement: .principal) {
            VStack(spacing: 0) {
                Text("BibleLib: Multi-Bible Reader").font(.headline)
                if showsChrome {
                    Text("\(viewModel.selectedCount) of \(viewModel.maxSelections) Bibles Selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            if showsChrome {
                Button { viewModel.fetchBibles() } label: { Image(systemName: "arrow.clockwise") }
                    .accessibilityLabel("Refresh")
                Button { showThemes = true } label: { Image(systemName: "circle.lefthalf.filled") }
                    .accessibilityLabel("Theme")
            }
        }
    }

    @ViewBuilder
    private var continueBar: some View {
        if case .loaded = viewModel.uiState {
            Button {
                if viewModel.isFirstInstall { viewModel.saveSelectionAndDownload() } else { viewModel.saveSelectionInBackground() }
            } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canProceed)
            .padding()
            .background(.bar)
        }
    }
}

#Preview {
    SelectionView()
        .environmentObject(ThemeManager())
}
