//
//  VerseListView.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct VerseListView: View {
    @ObservedObject var viewModel: ReaderViewModel
    @ObservedObject var autoScroll: AutoScrollController
    let scrollToTopTick: Int
    @Binding var isAtTop: Bool

    @AppStorage(PrefConstants.fontSize) private var fontSize = ReaderFontSize.standard
    @AppStorage(PrefConstants.readerFontFamily) private var fontFamily = "default"
    @AppStorage(PrefConstants.readerBackground) private var backgroundId = "default"

    @State private var visibleIndices: Set<Int> = []
    @State private var edgesArmed = false
    @State private var highlightQuery: String?
    @State private var positionTask: Task<Void, Never>?

    private var selection: VerseSelectionModel { viewModel.selection }
    private var page: ReaderBackgroundOption { ReaderBackgrounds.byId(backgroundId) }

    private struct AutoScrollKey: Equatable {
        let running: Bool
        let speed: Double
        let chapterId: String?
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if viewModel.hasPrevChapter {
                    edgeRow(.previous, label: viewModel.prevChapterLabel) { viewModel.navigateChapter(-1) }
                }

                ForEach(Array(viewModel.verses.enumerated()), id: \.element.verseId) { index, verse in
                    row(index: index, verse: verse)
                }

                if viewModel.hasNextChapter {
                    edgeRow(.next, label: viewModel.nextChapterLabel) { viewModel.navigateChapter(1) }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .task(id: viewModel.activeChapter?.id) {
                edgesArmed = false
                visibleIndices = []
                if viewModel.scrollTarget == nil { highlightQuery = nil }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled { edgesArmed = true }
            }
            .task(id: viewModel.scrollTarget) {
                guard let target = viewModel.scrollTarget else { return }
                highlightQuery = target.highlightQuery
                try? await Task.sleep(nanoseconds: 80_000_000)
                proxy.scrollTo(target.verseId, anchor: .top)
                viewModel.scrollTarget = nil
            }
            .task(id: AutoScrollKey(running: autoScroll.isRunning, speed: autoScroll.speed, chapterId: viewModel.activeChapter?.id)) {
                guard autoScroll.isRunning else { return }
                await runAutoScroll(proxy)
            }
            .onChange(of: scrollToTopTick) { _ in
                guard let first = viewModel.verses.first else { return }
                withAnimation { proxy.scrollTo(first.verseId, anchor: .top) }
            }
            .onChange(of: visibleIndices) { indices in
                isAtTop = indices.isEmpty || indices.contains(0)
                schedulePositionSave()
            }
        }
    }

    private func edgeRow(_ edge: ChapterEdgeRow.Edge, label: String, action: @escaping () -> Void) -> some View {
        ChapterEdgeRow(edge: edge, label: label, isArmed: edgesArmed, onTrigger: action)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private func row(index: Int, verse: VerseDisplay) -> some View {
        let colorHex = selection.bookmarks[verse.verseId]
        let isBookmarked = colorHex != nil

        return VerseRowView(
            verse: verse,
            font: ReaderFonts.byId(fontFamily),
            fontSize: fontSize,
            highlightQuery: highlightQuery,
            parallelTexts: viewModel.parallel.compactMap { chapter in
                chapter.text(forVerse: verse.number).map { ParallelText(abbr: chapter.abbr, text: $0) }
            },
            isBookmarked: isBookmarked,
            hasNote: selection.notedIds.contains(verse.verseId),
            textColor: page.textColor,
            secondaryTextColor: page.secondaryTextColor
        )
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(rowBackground(selected: selection.selectedIds.contains(verse.verseId), colorHex: colorHex))
        .id(verse.verseId)
        .onTapGesture { if selection.isSelecting { selection.toggle(verse.verseId) } }
        .onLongPressGesture(minimumDuration: 0.4) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selection.toggle(verse.verseId)
        }
        .swipeActions(edge: .leading) {
            Button { selection.toggleBookmark(verse) } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }
            .tint(AppColors.primary)
        }
        .swipeActions(edge: .trailing) {
            Button { selection.requestNote(for: verse) } label: {
                Label("Note", systemImage: "note.text")
            }
            .tint(AppColors.secondary)
        }
        .onAppear { visibleIndices.insert(index) }
        .onDisappear { visibleIndices.remove(index) }
    }

    private func rowBackground(selected: Bool, colorHex: String?) -> some View {
        ZStack {
            if let hex = colorHex, let color = Color(hex: hex) { color.opacity(0.35) }
            if selected { AppColors.primary.opacity(0.2) }
        }
    }

    private func schedulePositionSave() {
        positionTask?.cancel()
        positionTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled, let index = visibleIndices.min(), viewModel.verses.indices.contains(index) else { return }
            viewModel.verseViewed(viewModel.verses[index])
        }
    }

    private func runAutoScroll(_ proxy: ScrollViewProxy) async {
        var index = visibleIndices.min() ?? 0

        while !Task.isCancelled, index < viewModel.verses.count - 1 {
            let length = max(viewModel.verses[index].text.count, 20)
            let seconds = max(0.6, Double(length) / (80.0 * autoScroll.speed))
            withAnimation(.linear(duration: seconds)) {
                proxy.scrollTo(viewModel.verses[index + 1].verseId, anchor: .top)
            }
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            index += 1
        }

        if !Task.isCancelled && !viewModel.hasNextChapter { autoScroll.isRunning = false }
    }
}
