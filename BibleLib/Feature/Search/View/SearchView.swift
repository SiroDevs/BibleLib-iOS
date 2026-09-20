//
//  SearchView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(SearchViewModel.self)
    @EnvironmentObject private var router: AppRouter

    private var trimmedQuery: String { viewModel.query.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        List {
            if trimmedQuery.count < 3 {
                if !viewModel.searchHistory.isEmpty {
                    Section {
                        ForEach(viewModel.searchHistory) { entry in
                            Button {
                                viewModel.searchFromHistory(entry)
                            } label: {
                                Label(entry.qry, systemImage: "clock.arrow.circlepath")
                                    .foregroundStyle(.primary)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Recent searches")
                            Spacer()
                            Button("Clear") { viewModel.clearSearchHistory() }
                                .font(.footnote)
                                .textCase(nil)
                        }
                    }
                }
            } else if !viewModel.results.isEmpty {
                Section("\(viewModel.results.count) results") {
                    ForEach(viewModel.results) { verse in
                        Button { open(verse) } label: { resultRow(verse) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.isSearching {
                ProgressView()
            } else if trimmedQuery.count >= 3
                        && viewModel.results.isEmpty
                        && viewModel.searchedQuery == trimmedQuery {
                EmptyState(message: "No results for \(trimmedQuery)")
            } else if trimmedQuery.count < 3 && viewModel.searchHistory.isEmpty {
                EmptyState(message: "Search the scriptures.\nType at least 3 letters.")
            }
        }
        .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search scriptures...")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onChange(of: viewModel.query) { _ in viewModel.queryChanged() }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.bibles.count > 1 {
                    Menu {
                        Picker("Bible", selection: Binding(
                            get: { viewModel.selectedBibleAbbr },
                            set: { viewModel.selectBible($0) }
                        )) {
                            ForEach(viewModel.bibles) { bible in
                                Text("\(bible.abbreviation.uppercased()) · \(bible.name)").tag(bible.abbreviation)
                            }
                        }
                    } label: {
                        Label(viewModel.selectedBibleAbbr.uppercased(), systemImage: "book.closed")
                    }
                }
            }
        }
        .onAppear { viewModel.load() }
    }

    private func resultRow(_ verse: VerseDisplay) -> some View {
        let bookName = viewModel.bookNames[verse.bookId] ?? verse.bookId
        let chapter = verse.chapterId.split(separator: ".").last.map(String.init) ?? verse.chapterId

        return VStack(alignment: .leading, spacing: 4) {
            Text("\(bookName) \(chapter):\(verse.number)")
                .font(.headline)
                .foregroundStyle(AppColors.primary)
            Text(VerseRowView.highlighted(verse.text, query: trimmedQuery, color: AppColors.secondaryContainer))
                .font(.subheadline)
                .lineLimit(4)
        }
        .padding(.vertical, 2)
    }

    private func open(_ verse: VerseDisplay) {
        router.openReader(ReaderTarget(
            bibleAbbr: viewModel.selectedBibleAbbr,
            bookId: verse.bookId,
            chapterId: verse.chapterId,
            verseId: verse.verseId,
            searchQuery: trimmedQuery
        ))
    }
}
