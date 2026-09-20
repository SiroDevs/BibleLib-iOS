//
//  HistoryView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(HistoryViewModel.self)
    @EnvironmentObject private var router: AppRouter
    @State private var showClearConfirm = false

    var body: some View {
        List {
            ForEach(viewModel.days) { day in
                Section(day.title) {
                    ForEach(day.entries) { entry in
                        Button {
                            router.openReader(ReaderTarget(
                                bibleAbbr: entry.bibleAbbr,
                                bookId: entry.bookId,
                                chapterId: entry.chapterId
                            ))
                        } label: {
                            row(entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.isLoading && viewModel.days.isEmpty {
                EmptyState(message: "No reading history yet.")
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.days.isEmpty {
                    Button(role: .destructive) { showClearConfirm = true } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog("Clear reading history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear History", role: .destructive) { viewModel.clear() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { viewModel.load() }
    }

    private func row(_ entry: HistoryEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.chapterRef.isEmpty ? entry.bookName : entry.chapterRef)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(entry.bibleAbbr.uppercased())
                    if let verse = entry.verseNumber { Text("· verse \(verse)") }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.readAt, style: .time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
