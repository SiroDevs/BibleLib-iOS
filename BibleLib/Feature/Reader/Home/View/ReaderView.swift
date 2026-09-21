//
//  ReaderView.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

private enum ReaderSheet: String, Identifiable {
    case books, chapters, bibles, quickSettings
    case search, history, bookmarks, lists, opener

    var id: String { rawValue }
}

struct ReaderView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(ReaderViewModel.self)
    @StateObject private var autoScroll = AutoScrollController()
    @AppStorage(PrefConstants.readerBackground) private var backgroundId = "default"

    @State private var activeSheet: ReaderSheet?
    @State private var showSettings = false
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
            .toolbar { navigationToolbar }
            .toolbar { bottomToolbar }
            .toolbar(viewModel.isQueueActive || selection.isSelecting ? .hidden : .visible, for: .bottomBar)
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
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

    private var notesBinding: Binding<NotesRequest?> {
        Binding(get: { selection.notesRequest }, set: { selection.notesRequest = $0 })
    }

    private func open(_ target: ReaderTarget) {
        activeSheet = nil
        viewModel.open(target)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.uiState {
        case .error(let message):
            ErrorState(message: message) { viewModel.open() }
        case .loaded:
            VerseListView(viewModel: viewModel, autoScroll: autoScroll, scrollToTopTick: scrollToTopTick, isAtTop: $isAtTop)
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
                onOpenScriptureOpener: { activeSheet = .opener }
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
            ScriptureQueueBar(
                items: viewModel.queueItems,
                activeItemId: viewModel.queueActiveItemId,
                onSelect: viewModel.jump(to:),
                onOptions: { activeSheet = .quickSettings },
                onClose: viewModel.dismissQueue
            )
        }
    }

    // MARK: Toolbars

    @ToolbarContentBuilder
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if selection.isSelecting {
                Button(action: selection.clear) { Image(systemName: "xmark") }
                    .accessibilityLabel("Cancel selection")
            }
        }

        ToolbarItem(placement: .principal) {
            if selection.isSelecting {
                Text("\(selection.selectedIds.count) selected").font(.headline)
            } else {
                titleMenu
            }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if selection.isSelecting {
                selectionActions
            } else {
                Button { activeSheet = .search } label: { Image(systemName: "magnifyingglass") }
                    .accessibilityLabel("Search")
                moreMenu
            }
        }
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button { autoScroll.toggle() } label: {
                Image(systemName: autoScroll.isRunning ? "pause.fill" : "play.fill")
            }
            .accessibilityLabel(autoScroll.isRunning ? "Stop auto scroll" : "Start auto scroll")

            Spacer()
            Button { viewModel.navigateChapter(-1) } label: { Image(systemName: "chevron.left") }
                .disabled(!viewModel.hasPrevChapter)
                .accessibilityLabel("Previous chapter")

            Spacer()
            Button { activeSheet = .chapters } label: {
                Text("Chapter \(viewModel.activeChapter?.number ?? "")").font(.subheadline.weight(.semibold))
            }
            .disabled(viewModel.chapters.isEmpty)

            Spacer()
            Button { viewModel.navigateChapter(1) } label: { Image(systemName: "chevron.right") }
                .disabled(!viewModel.hasNextChapter)
                .accessibilityLabel("Next chapter")

            Spacer()
            Button { activeSheet = .quickSettings } label: { Image(systemName: "slider.horizontal.3") }
                .accessibilityLabel("Options")
        }
    }

    private var titleMenu: some View {
        VStack(spacing: 1) {
            Button { activeSheet = .bibles } label: {
                Label("\(viewModel.activeBibleAbbr.uppercased()) · \(viewModel.activeBible?.name ?? "")", systemImage: "chevron.down")
                    .labelStyle(TrailingIconLabelStyle())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button {
                if viewModel.isQueueActive { showBookLockedAlert = true } else { activeSheet = .books }
            } label: {
                Label("\(viewModel.activeBook?.name ?? "") \(viewModel.activeChapter?.number ?? "")", systemImage: "chevron.down")
                    .labelStyle(TrailingIconLabelStyle())
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private var moreMenu: some View {
        Menu {
            Button { activeSheet = .lists } label: { Label("Scripture Lists", systemImage: "list.bullet.rectangle") }
            Button { activeSheet = .bookmarks } label: { Label("Bookmarks & Notes", systemImage: "bookmark") }
            Button { activeSheet = .history } label: { Label("History", systemImage: "clock.arrow.circlepath") }

            if let context = viewModel.context, let text = ReaderShareText.chapter(context, bible: viewModel.activeBible) {
                ShareLink(item: text) { Label("Share Chapter", systemImage: "square.and.arrow.up") }
            }

            Divider()
            Button { showSettings = true } label: { Label("Settings", systemImage: "gearshape") }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("More")
    }

    @ViewBuilder
    private var selectionActions: some View {
        Button { selection.showColorPicker = true } label: { Image(systemName: "highlighter") }
            .accessibilityLabel("Highlight and bookmark")

        Button(action: selection.requestNoteForSelection) { Image(systemName: "note.text.badge.plus") }
            .disabled(selection.selectedIds.count != 1)
            .accessibilityLabel("Add note")

        if let context = viewModel.context,
           let text = ReaderShareText.verses(selection.selectedIds, in: context, bible: viewModel.activeBible) {
            Button {
                UIPasteboard.general.string = text
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                selection.clear()
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .accessibilityLabel("Copy")

            ShareLink(item: text) { Image(systemName: "square.and.arrow.up") }
        }
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(_ sheet: ReaderSheet) -> some View {
        switch sheet {
        case .books:
            BookPickerSheet(books: viewModel.books, activeBookId: viewModel.activeBook?.id, onSelect: { viewModel.select($0) })
        case .chapters:
            ChapterPickerSheet(chapters: viewModel.chapters, activeChapterId: viewModel.activeChapter?.id, onSelect: { viewModel.select($0) })
        case .bibles:
            BibleSelectorSheet(bibles: viewModel.bibles, activeAbbr: viewModel.activeBibleAbbr, onSelect: viewModel.setPrimary)
        case .quickSettings:
            QuickSettingsSheet()
        case .search:
            ModalNavigation { SearchView(onOpen: open) }
        case .history:
            ModalNavigation { HistoryView(onOpen: open) }
        case .bookmarks:
            ModalNavigation { BookmarkNotesView(onOpen: open) }
        case .lists:
            ModalNavigation { ScriptureListsView(onOpen: open) }
        case .opener:
            ModalNavigation {
                ScriptureOpenerView(bibleAbbr: viewModel.activeBibleAbbr, bibleName: viewModel.activeBible?.name ?? "", onOpen: open)
            }
        }
    }
}

private struct ReaderSelectionPresentations: ViewModifier {
    @ObservedObject var selection: VerseSelectionModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $selection.showColorPicker) {
                HighlightColorSheet(onChoose: selection.applyHighlight, onCancel: { selection.showColorPicker = false })
            }
            .confirmationDialog(
                "Highlight applied",
                isPresented: Binding(
                    get: { selection.pendingColor != nil },
                    set: { if !$0 { selection.pendingColor = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Bookmark only") { selection.confirmHighlight(withNote: false) }
                Button("Bookmark with note") { selection.confirmHighlight(withNote: true) }
                Button("Cancel", role: .cancel) { selection.pendingColor = nil }
            } message: {
                Text("Save the highlighted verses as a bookmark, or add a note too.")
            }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.font(.system(size: 9, weight: .bold))
        }
    }
}
