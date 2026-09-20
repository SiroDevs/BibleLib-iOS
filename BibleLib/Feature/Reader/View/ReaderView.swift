//
//  ReaderView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

private enum ReaderSheet: String, Identifiable {
    case books, chapters, bibles, quickSettings
    var id: String { rawValue }
}

struct ReaderView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(ReaderViewModel.self)
    @StateObject private var autoScroll = AutoScrollController()
    @EnvironmentObject private var router: AppRouter

    @State private var activeSheet: ReaderSheet?
    @State private var hasInitialized = false
    @State private var showBookLockedAlert = false
    @State private var isAtTop = true
    @State private var scrollToTopTick = 0
    @State private var didCopy = false

    var body: some View {
        let background = ReaderBackgrounds.byId(viewModel.readerBackgroundId)
        presentations(of: screen(background: background))
    }

    private func screen(background: ReaderBackgroundOption) -> some View {
        content(background: background)
            .background(background.background)
            .overlay(alignment: .bottomTrailing) {
                if !viewModel.isSelectionMode && viewModel.error == nil && !viewModel.isLoading {
                    ReaderFloatingButtons(
                        isAtTop: isAtTop,
                        onScrollToTop: { scrollToTopTick += 1 },
                        onOpenScriptureOpener: {
                            router.push(.scriptureOpener(bibleAbbr: viewModel.activeBibleAbbr, bibleName: viewModel.activeBible))
                        }
                    )
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if autoScroll.isRunning {
                    AutoScrollSpeedButtons(controller: autoScroll)
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if viewModel.isScriptureModeActive {
                    ScriptureQueueBar(
                        items: viewModel.queueItems,
                        activeItemId: viewModel.queueActiveItemId,
                        onSelect: { viewModel.jumpToQueueItem($0) },
                        onOptions: { activeSheet = .quickSettings },
                        onClose: { viewModel.dismissScriptureQueue() }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navigationToolbar }
            .toolbar { bottomToolbar }
            .toolbar(viewModel.isScriptureModeActive || viewModel.isSelectionMode ? .hidden : .visible, for: .bottomBar)
    }

    private func presentations<V: View>(of view: V) -> some View {
        view
            .sheet(item: $activeSheet) { sheet in
                sheetContent(sheet)
            }
            .sheet(isPresented: Binding(
                get: { viewModel.showColorPicker },
                set: { if !$0 { viewModel.dismissColorPicker() } }
            )) {
                HighlightColorSheet(
                    onChoose: { viewModel.chooseHighlightColor($0) },
                    onCancel: { viewModel.dismissColorPicker() }
                )
            }
            .confirmationDialog(
                "Highlight applied",
                isPresented: Binding(
                    get: { viewModel.pendingHighlightColor != nil },
                    set: { if !$0 { viewModel.cancelPendingHighlight() } }
                ),
                titleVisibility: .visible
            ) {
                Button("Bookmark only") { viewModel.confirmBookmarkOnly() }
                Button("Bookmark with note") { viewModel.confirmBookmarkWithNotes() }
                Button("Cancel", role: .cancel) { viewModel.cancelPendingHighlight() }
            } message: {
                Text("Save the highlighted verses as a bookmark, or add a note too.")
            }
            .alert("Finish your scripture list first", isPresented: $showBookLockedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Close the scripture list to switch books.")
            }
            .onChange(of: viewModel.notesRequest) { request in
                guard let request else { return }
                router.push(.notes(request))
                viewModel.consumeNotesRequest()
            }
            .onChange(of: router.readerTarget) { target in
                guard let target else { return }
                router.readerTarget = nil
                Task { await viewModel.initialize(target: target) }
            }
            .onChange(of: viewModel.isSelectionMode) { selecting in
                if selecting { autoScroll.isRunning = false }
            }
            .task {
                guard !hasInitialized else { return }
                hasInitialized = true
                let target = router.readerTarget
                router.readerTarget = nil
                await viewModel.initialize(target: target)
            }
            .task(id: viewModel.error) {
                // The primary Bible may still be downloading: keep checking until it lands.
                while viewModel.error != nil && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if Task.isCancelled { break }
                    await viewModel.initialize(target: nil)
                }
            }
            .onAppear {
                guard hasInitialized else { return }
                Task {
                    await viewModel.refresh()
                    viewModel.refreshNotedVerses()
                }
            }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(background: ReaderBackgroundOption) -> some View {
        if let error = viewModel.error {
            ErrorState(message: error) {
                Task { await viewModel.initialize(target: nil) }
            }
        } else if viewModel.isLoading && viewModel.verses.isEmpty {
            List {
                ForEach(0..<8, id: \.self) { _ in
                    Text(String(repeating: "In the beginning God created the heaven and the earth. ", count: 2))
                        .redacted(reason: .placeholder)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .disabled(true)
        } else {
            VerseListView(
                viewModel: viewModel,
                autoScroll: autoScroll,
                background: background,
                scrollToTopTick: scrollToTopTick,
                isAtTop: $isAtTop
            )
        }
    }

    @ToolbarContentBuilder
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if viewModel.isSelectionMode {
                Button {
                    viewModel.clearSelection()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Cancel selection")
            }
        }

        ToolbarItem(placement: .principal) {
            if viewModel.isSelectionMode {
                Text("\(viewModel.selectedVerseIds.count) selected")
                    .font(.headline)
            } else {
                titleMenu
            }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if viewModel.isSelectionMode {
                selectionActions
            } else {
                Button {
                    router.push(.search)
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel("Search")

                moreMenu
            }
        }
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                autoScroll.toggle()
            } label: {
                Image(systemName: autoScroll.isRunning ? "pause.fill" : "play.fill")
            }
            .accessibilityLabel(autoScroll.isRunning ? "Stop auto scroll" : "Start auto scroll")

            Spacer()

            Button {
                viewModel.navigateChapter(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.hasPrevChapter)
            .accessibilityLabel("Previous chapter")

            Spacer()

            Button {
                activeSheet = .chapters
            } label: {
                Text("Chapter \(viewModel.activeChapter?.number ?? "")")
                    .font(.subheadline.weight(.semibold))
            }
            .disabled(viewModel.chapters.isEmpty)

            Spacer()

            Button {
                viewModel.navigateChapter(1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.hasNextChapter)
            .accessibilityLabel("Next chapter")

            Spacer()

            Button {
                activeSheet = .quickSettings
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .accessibilityLabel("Options")
        }
    }

    private var titleMenu: some View {
        VStack(spacing: 1) {
            Button {
                activeSheet = .bibles
            } label: {
                HStack(spacing: 3) {
                    Text("\(viewModel.activeBibleAbbr.uppercased()) · \(viewModel.activeBible)")
                        .lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Button {
                if viewModel.isScriptureModeActive {
                    showBookLockedAlert = true
                } else {
                    activeSheet = .books
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(viewModel.activeBook?.name ?? "") \(viewModel.activeChapter?.number ?? "")")
                        .font(.headline)
                        .lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private var moreMenu: some View {
        Menu {
            Button { router.push(.scriptureLists) } label: { Label("Scripture Lists", systemImage: "list.bullet.rectangle") }
            Button { router.push(.bookmarksNotes) } label: { Label("Bookmarks & Notes", systemImage: "bookmark") }
            Button { router.push(.history) } label: { Label("History", systemImage: "clock.arrow.circlepath") }

            if let text = viewModel.buildActiveChapterShareText() {
                ShareLink(item: text) { Label("Share Chapter", systemImage: "square.and.arrow.up") }
            }

            Divider()
            Button { router.push(.settings) } label: { Label("Settings", systemImage: "gearshape") }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("More")
    }

    @ViewBuilder
    private var selectionActions: some View {
        Button {
            viewModel.openColorPicker()
        } label: {
            Image(systemName: "highlighter")
        }
        .accessibilityLabel("Highlight and bookmark")

        Button {
            viewModel.openNotesForSelection()
        } label: {
            Image(systemName: "note.text.badge.plus")
        }
        .disabled(viewModel.selectedVerseIds.count != 1)
        .accessibilityLabel("Add note")

        if let text = viewModel.buildSelectionShareText() {
            Button {
                UIPasteboard.general.string = text
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                viewModel.clearSelection()
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .accessibilityLabel("Copy")

            ShareLink(item: text) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ReaderSheet) -> some View {
        switch sheet {
        case .books:
            BookPickerSheet(books: viewModel.books, activeBookId: viewModel.activeBook?.id) { viewModel.selectBook($0) }
        case .chapters:
            ChapterPickerSheet(chapters: viewModel.chapters, activeChapterId: viewModel.activeChapter?.id) { viewModel.selectChapter($0) }
        case .bibles:
            BibleSelectorSheet(
                bibles: viewModel.savedBibles,
                activeAbbr: viewModel.activeBibleAbbr,
                onSelect: { viewModel.setPrimaryBible($0) },
                onManage: { router.push(.bibles) }
            )
        case .quickSettings:
            QuickSettingsSheet(viewModel: viewModel)
        }
    }
}
