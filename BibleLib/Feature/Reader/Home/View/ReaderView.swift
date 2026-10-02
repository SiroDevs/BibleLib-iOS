//
//  ReaderView.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct ReaderView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(ReaderViewModel.self)
    @StateObject private var autoScroll = AutoScrollController()
    @AppStorage(PrefConstants.readerBackground) private var backgroundId = "default"

    @State private var activeSheet: ReaderSheet?
    @State private var showSettings = false
    @State private var route: ReaderRoute?
    @State private var showBookLockedAlert = false
    @State private var isAtTop = true
    @State private var scrollToTopTick = 0
    @State private var hasStarted = false

    private var selection: VerseSelectionModel { viewModel.selection }

    private var errorMessage: String? {
        if case .error(let message) = viewModel.uiState { return message }
        return nil
    }

    var body: some View {
        content
            .background(ReaderBackgrounds.byId(backgroundId).background)
            .overlay(alignment: .bottomTrailing) { floatingButtons }
            .overlay(alignment: .bottomLeading) { speedButtons }
            .safeAreaInset(edge: .bottom, spacing: 0) { queueBar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbar { bottomBarContent }
            .toolbar(viewModel.isQueueActive || selection.isSelecting ? .hidden : .visible, for: .bottomBar)
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(isPresented: routeBinding) { routeContent }
            .onChange(of: route) { if $0 == nil { viewModel.refresh() } }
            .sheet(item: $activeSheet, onDismiss: viewModel.refresh) { sheet in
                sheetContent(sheet)
            }
            .sheet(item: notesBinding) { request in
                ModalNavigation { NotesView(request: request) }
            }
            .modifier(ReaderSelectionPresentations(selection: selection))
            .alert("Finish your scripture list first", isPresented: $showBookLockedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Close the scripture list to switch books.")
            }
            .onChange(of: selection.isSelecting) { selecting in
                if selecting { autoScroll.isRunning = false }
            }
            .task {
                guard !hasStarted else { return }
                hasStarted = true
                viewModel.open()
            }
            .task(id: errorMessage) {
                while errorMessage != nil && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if !Task.isCancelled { viewModel.open() }
                }
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if selection.isSelecting {
            ReaderSelectionToolbar(
                viewModel: viewModel,
                onCancel: selection.clear,
                onHighlight: { selection.showColorPicker = true },
                onAddNote: selection.requestNoteForSelection,
                onCopy: copySelectionToPasteboard,
                shareText: selectedShareText
            )
        } else {
            ReaderNormalToolbar(
                viewModel: viewModel,
                onTapBible: { activeSheet = .bibles },
                onTapBook: {
                    if viewModel.isQueueActive {
                        showBookLockedAlert = true
                    } else {
                        activeSheet = .books
                    }
                },
                onSearch: { route = .search },
                moreMenu: {
                    ReaderMoreMenu(
                        onLists: { route = .lists },
                        onBookmarks: { route = .bookmarks },
                        onHistory: { route = .history },
                        shareChapterText: shareChapterText,
                        onSettings: { showSettings = true }
                    )
                }
            )
        }
    }

    @ToolbarContentBuilder
    private var bottomBarContent: some ToolbarContent {
        ReaderBottomBar(
            viewModel: viewModel,
            autoScroll: autoScroll,
            onChapters: { activeSheet = .chapters },
            onOptions: { activeSheet = .quickSettings }
        )
    }

    private var selectedShareText: String? {
        guard let context = viewModel.context else { return nil }
        return ReaderShareText.verses(selection.selectedIds, in: context, bible: viewModel.activeBible)
    }

    private var shareChapterText: String? {
        guard let context = viewModel.context else { return nil }
        return ReaderShareText.chapter(context, bible: viewModel.activeBible)
    }

    private func copySelectionToPasteboard() {
        guard let text = selectedShareText else { return }
        UIPasteboard.general.string = text
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        selection.clear()
    }

    private var notesBinding: Binding<NotesRequest?> {
        Binding(get: { selection.notesRequest }, set: { selection.notesRequest = $0 })
    }

    private var routeBinding: Binding<Bool> {
        Binding(get: { route != nil }, set: { if !$0 { route = nil } })
    }

    private func open(_ target: ReaderTarget) {
        activeSheet = nil
        route = nil
        viewModel.open(target)
    }

    @ViewBuilder
    private var routeContent: some View {
        switch route {
            case .bibles:
                BiblesView()
            case .bookmarks:
                BookmarkNotesView(onOpen: open)
            case .history:
                HistoryView(onOpen: open)
            case .search:
                SearchView(onOpen: open)
            case .lists:
                ScriptureListsView(onOpen: open)
            case .opener:
                ScriptureOpenerView(
                    bibleAbbr: viewModel.activeBibleAbbr,
                    bibleName: viewModel.activeBible?.name ?? "",
                    onOpen: open
                )
            case nil:
                EmptyView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.uiState {
            case .error(let message):
                ErrorState(message: message) { viewModel.open() }
            case .loaded:
                VerseListView(
                    viewModel: viewModel,
                    autoScroll: autoScroll,
                    scrollToTopTick: scrollToTopTick,
                    isAtTop: $isAtTop
                )
            default:
                List(0..<8, id: \.self) { _ in
                    Text(String(repeating: "In the beginning God created the heaven and the earth. ", count: 2))
                        .redacted(reason: .placeholder)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .disabled(true)
        }
    }

    @ViewBuilder
    private var floatingButtons: some View {
        if case .loaded = viewModel.uiState, !selection.isSelecting {
            ReaderFloatingButtons(
                isAtTop: isAtTop,
                onScrollToTop: { scrollToTopTick += 1 },
                onOpenScriptureOpener: { route = .opener }
            )
            .padding(16)
        }
    }

    @ViewBuilder
    private var speedButtons: some View {
        if autoScroll.isRunning {
            AutoScrollSpeedButtons(controller: autoScroll).padding(16)
        }
    }

    @ViewBuilder
    private var queueBar: some View {
        if viewModel.isQueueActive {
            ScriptureQueue(
                viewModel: viewModel,
                onOptions: { activeSheet = .quickSettings }
            )
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ReaderSheet) -> some View {
        switch sheet {
        case .books:
            BookPickerSheet(viewModel: viewModel)
        case .chapters:
            ChapterPickerSheet(viewModel: viewModel)
        case .quickSettings:
            QuickSettingsSheet()
        case .bibles:
            BibleSelectorSheet(viewModel: viewModel)
        }
    }
}
