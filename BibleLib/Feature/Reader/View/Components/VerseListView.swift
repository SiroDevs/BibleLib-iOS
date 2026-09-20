//
//  VerseListView.swift
//  BibleLib
//
//  The scrolling chapter text: verse rows with swipe actions and long-press
//  selection, pull-to-continue chapter edges, scroll restoration, position saving
//  and auto-scroll.
//

import SwiftUI

struct VerseListView: View {
    @ObservedObject var viewModel: ReaderViewModel
    @ObservedObject var autoScroll: AutoScrollController
    let background: ReaderBackgroundOption
    let scrollToTopTick: Int
    @Binding var isAtTop: Bool

    @State private var visibleIndices: Set<Int> = []
    @State private var edgesArmed = false
    @State private var positionTask: Task<Void, Never>?

    private struct AutoScrollKey: Equatable {
        let running: Bool
        let speed: Double
        let chapterId: String?
    }

    var body: some View {
        let font = ReaderFonts.byId(viewModel.fontFamilyId)

        ScrollViewReader { proxy in
            List {
                if viewModel.hasPrevChapter {
                    ChapterEdgeRow(edge: .previous, label: viewModel.prevChapterLabel, isArmed: edgesArmed) {
                        viewModel.navigateChapter(-1)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                ForEach(Array(viewModel.verses.enumerated()), id: \.element.verseId) { index, verse in
                    row(index: index, verse: verse, font: font)
                }

                if viewModel.hasNextChapter {
                    ChapterEdgeRow(edge: .next, label: viewModel.nextChapterLabel, isArmed: edgesArmed) {
                        viewModel.navigateChapter(1)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            // Edges only act once the chapter has settled, so restoring the scroll
            // position can't be mistaken for the user pulling past the top.
            .task(id: viewModel.activeChapter?.id) {
                edgesArmed = false
                visibleIndices = []
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled { edgesArmed = true }
            }
            .task(id: viewModel.restoreVerseId) {
                guard let target = viewModel.restoreVerseId else { return }
                try? await Task.sleep(nanoseconds: 80_000_000)
                proxy.scrollTo(target, anchor: .top)
                viewModel.consumeRestoreVerseTarget()
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

    // MARK: - Rows

    private func row(index: Int, verse: VerseDisplay, font: ReaderFontOption) -> some View {
        let isSelected = viewModel.selectedVerseIds.contains(verse.verseId)
        let colorHex = viewModel.bookmarks[verse.verseId]
        let isBookmarked = colorHex != nil
        let parallel: [ParallelText] = viewModel.parallelOrder.compactMap { abbr in
            guard let match = viewModel.parallelVerses[abbr]?.first(where: { $0.number == verse.number }) else { return nil }
            return ParallelText(abbr: abbr, text: match.text)
        }

        return VerseRowView(
            verse: verse,
            font: font,
            fontSize: viewModel.fontSize,
            highlightQuery: viewModel.highlightQuery,
            parallelTexts: parallel,
            isBookmarked: isBookmarked,
            hasNote: viewModel.notedVerseIds.contains(verse.verseId),
            textColor: background.textColor,
            secondaryTextColor: background.secondaryTextColor
        )
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(rowBackground(isSelected: isSelected, colorHex: colorHex))
        .id(verse.verseId)
        .onTapGesture {
            if viewModel.isSelectionMode { viewModel.toggleVerseSelected(verse.verseId) }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.toggleVerseSelected(verse.verseId)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.quickToggleBookmark(verse.verseId)
            } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }
            .tint(AppColors.primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                viewModel.requestNotes(forVerse: verse.verseId)
            } label: {
                Label("Note", systemImage: "note.text")
            }
            .tint(AppColors.secondary)
        }
        .onAppear { visibleIndices.insert(index) }
        .onDisappear { visibleIndices.remove(index) }
    }

    private func rowBackground(isSelected: Bool, colorHex: String?) -> some View {
        ZStack {
            if let hex = colorHex, !hex.isEmpty, let color = Color(hex: hex) {
                color.opacity(0.35)
            }
            if isSelected {
                AppColors.primary.opacity(0.2)
            }
        }
    }

    // MARK: - Position saving

    /// Remembers the top-most verse a second after scrolling stops, so the app can
    /// reopen at the same place (Android: debounced scroll position).
    private func schedulePositionSave() {
        positionTask?.cancel()
        positionTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled,
                  let index = visibleIndices.min(),
                  viewModel.verses.indices.contains(index) else { return }
            let verse = viewModel.verses[index]
            viewModel.onVerseScrollPositionChanged(verseId: verse.verseId, verseNumber: verse.number)
        }
    }

    // MARK: - Auto scroll

    /// SwiftUI lists can't scroll by a pixel amount, so auto-scroll glides from verse
    /// to verse, spending time in proportion to each verse's length.
    private func runAutoScroll(_ proxy: ScrollViewProxy) async {
        var index = visibleIndices.min() ?? 0

        while !Task.isCancelled, index < viewModel.verses.count - 1 {
            let length = max(viewModel.verses[index].text.count, 20)
            let seconds = max(0.6, Double(length) / (80.0 * autoScroll.speed))
            let next = viewModel.verses[index + 1]

            withAnimation(.linear(duration: seconds)) {
                proxy.scrollTo(next.verseId, anchor: .top)
            }
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            index += 1
        }

        // At the end of a chapter with a next one, the edge row carries on; otherwise stop.
        if !Task.isCancelled && !viewModel.hasNextChapter {
            autoScroll.isRunning = false
        }
    }
}
