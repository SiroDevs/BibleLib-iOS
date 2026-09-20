//
//  BookmarkNotesView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct BookmarkNotesView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(BookmarkNotesViewModel.self)
    @EnvironmentObject private var router: AppRouter

    @State private var tab = 0
    @State private var showClearConfirm = false

    var body: some View {
        List {
            if tab == 0 {
                ForEach(viewModel.bookmarks) { item in
                    Button { openBookmark(item) } label: { bookmarkRow(item) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    viewModel.deleteBookmarks(offsets.map { viewModel.bookmarks[$0] })
                }
            } else {
                ForEach(viewModel.notes) { item in
                    Button { openNote(item) } label: { noteRow(item) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    viewModel.deleteNotes(offsets.map { viewModel.notes[$0] })
                }
            }
        }
        .overlay {
            if !viewModel.isLoading {
                if tab == 0 && viewModel.bookmarks.isEmpty {
                    EmptyState(message: "No bookmarks yet.\nSwipe right on a verse to bookmark it.")
                } else if tab == 1 && viewModel.notes.isEmpty {
                    EmptyState(message: "No notes yet.\nSwipe left on a verse to add one.")
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker("Section", selection: $tab) {
                Text("Bookmarks").tag(0)
                Text("Notes").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .navigationTitle("Bookmarks & Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !(viewModel.bookmarks.isEmpty && viewModel.notes.isEmpty) {
                    EditButton()
                    Button(role: .destructive) { showClearConfirm = true } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog("Clear all bookmarks and notes?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { viewModel.clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
        .onAppear { viewModel.load() }
    }

    private func bookmarkRow(_ item: BookmarkItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: item.bookmark.colorHex ?? "") ?? AppColors.primary)
                .frame(width: 12, height: 12)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.reference).font(.headline)
                    Spacer()
                    Text(item.bibleAbbr.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                if !item.verseText.isEmpty {
                    Text(item.verseText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func noteRow(_ item: NoteItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.reference).font(.headline)
                Spacer()
                Text(item.note.bibleAbbr.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(item.note.noteText)
                .font(.subheadline)
                .lineLimit(3)
            Text(item.note.updatedAt, style: .date)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func openBookmark(_ item: BookmarkItem) {
        router.openReader(ReaderTarget(
            bibleAbbr: item.bookmark.bibleAbbr,
            bookId: item.bookmark.bookId,
            chapterId: item.bookmark.chapterId,
            verseId: item.bookmark.verseId
        ))
    }

    private func openNote(_ item: NoteItem) {
        router.push(.notes(NotesRequest(
            bibleAbbr: item.note.bibleAbbr,
            verseId: item.note.verseId,
            bookId: item.note.bookId,
            chapterId: item.note.chapterId,
            title: item.note.title,
            verseText: item.note.verseText
        )))
    }
}
