//
//  ScriptureOpenerView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct ScriptureOpenerView: View {
    let bibleAbbr: String
    let bibleName: String
    let onOpen: (ReaderTarget) -> Void

    @StateObject private var viewModel = DiContainer.shared.resolve(ScriptureOpenerViewModel.self)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyState(message: error)
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(viewModel.rows) { row in
                        if row.locked {
                            lockedRow(row)
                        } else {
                            activeSection(row)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Scripture Opener")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Scripture Opener").font(.headline)
                    Text(bibleName).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { viewModel.initialize(bibleAbbr: bibleAbbr, bibleName: bibleName) }
        .onChange(of: viewModel.readerTarget) { target in
            guard let target else { return }
            viewModel.consumeReaderTarget()
            onOpen(target)
        }
        .onChange(of: viewModel.closeRequested) { requested in
            guard requested else { return }
            viewModel.consumeClose()
            dismiss()
        }
    }

    private func lockedRow(_ row: ScriptureSearchRow) -> some View {
        Section {
            Label(row.reference, systemImage: "checkmark.circle.fill")
                .foregroundStyle(AppColors.primary)
        }
    }

    private func activeSection(_ row: ScriptureSearchRow) -> some View {
        Section {
            fieldButton("Book", value: row.bookLabel, field: .book, row: row, enabled: true)
            if row.expanded == .book { BookOptions(row: row, viewModel: viewModel) }

            fieldButton("Chapter", value: row.chapterLabel, field: .chapter, row: row, enabled: row.canExpandChapter)
            if row.expanded == .chapter { ChapterOptions(row: row, viewModel: viewModel) }

            fieldButton("Verse", value: row.verseLabel, field: .verse, row: row, enabled: row.canExpandVerse)
            if row.expanded == .verse { VerseOptions(row: row, viewModel: viewModel) }

            if row.isComplete {
                actions(for: row)
            }
        } header: {
            Text(viewModel.rows.contains { $0.locked } ? "Add another scripture" : "Find a scripture")
        } footer: {
            if !row.isComplete {
                Text("Choose a book, chapter and verse.")
            }
        }
    }

    private func fieldButton(_ title: String, value: String, field: ExpandedField, row: ScriptureSearchRow, enabled: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleField(rowId: row.id, field: field)
            }
        } label: {
            HStack {
                Text(title).foregroundStyle(enabled ? Color.primary : Color.secondary)
                Spacer()
                Text(value.isEmpty ? "Select" : value)
                    .foregroundStyle(value.isEmpty ? Color.secondary : AppColors.primary)
                Image(systemName: row.expanded == field ? "chevron.up" : "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .disabled(!enabled)
    }

    @ViewBuilder
    private func actions(for row: ScriptureSearchRow) -> some View {
        Button {
            viewModel.openScripture(rowId: row.id)
        } label: {
            Label("Open \(row.reference)", systemImage: "book")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        Button {
            withAnimation { viewModel.addToQueue(rowId: row.id) }
        } label: {
            Label("Add to Queue", systemImage: "plus.circle")
        }

        Button {
            viewModel.addToQueueAndFinish(rowId: row.id)
        } label: {
            Label("Save Queue & Start Reading", systemImage: "list.bullet.rectangle")
        }

        Button {
            viewModel.addToQueueAndClose(rowId: row.id)
        } label: {
            Label("Save Queue & Return", systemImage: "arrow.uturn.backward")
        }
    }
}

private struct BookOptions: View {
    let row: ScriptureSearchRow
    @ObservedObject var viewModel: ScriptureOpenerViewModel
    @State private var query = ""

    private var filtered: [Book] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let ordered = row.books.sorted { $0.sortOrder < $1.sortOrder }
        guard !trimmed.isEmpty else { return ordered }
        return ordered.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) || $0.abbreviation.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        TextField("Search books", text: $query)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

        ForEach(filtered) { book in
            Button {
                withAnimation { viewModel.selectBook(rowId: row.id, book: book) }
            } label: {
                HStack {
                    Text(book.name).foregroundStyle(.primary)
                    Spacer()
                    if row.selectedBook?.id == book.id {
                        Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                    }
                }
            }
        }
    }
}

private struct ChapterOptions: View {
    let row: ScriptureSearchRow
    @ObservedObject var viewModel: ScriptureOpenerViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
            ForEach(row.chapters) { chapter in
                let isSelected = row.selectedChapter?.id == chapter.id
                Button {
                    withAnimation { viewModel.selectChapter(rowId: row.id, chapter: chapter) }
                } label: {
                    Text(chapter.number)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(isSelected ? AppColors.onPrimary : Color.primary)
                        .background(isSelected ? AppColors.primary : Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct VerseOptions: View {
    let row: ScriptureSearchRow
    @ObservedObject var viewModel: ScriptureOpenerViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
            ForEach(row.verses) { verse in
                let isSelected = row.selectedVerseNumber == verse.number
                Button {
                    withAnimation { viewModel.selectVerse(rowId: row.id, number: verse.number) }
                } label: {
                    Text("\(verse.number)")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(isSelected ? AppColors.onPrimary : Color.primary)
                        .background(isSelected ? AppColors.primary : Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
