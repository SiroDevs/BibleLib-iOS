//
//  ReaderView.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

struct ReaderView: View {
    @StateObject private var viewModel: ReaderViewModel

    init(bibleAbbr: String) {
        _viewModel = StateObject(
            wrappedValue: DiContainer.shared.resolve(ReaderViewModel.self, argument: bibleAbbr)
        )
    }

    var body: some View {
        Group {
            switch viewModel.uiState {
            case .idle:
                LoadingState(title: "Loading…")
            case .error(let message):
                ErrorState(message: message) { viewModel.load() }
            default:
                content
            }
        }
        .navigationTitle(viewModel.currentChapter.map { "\(viewModel.currentBook?.name ?? "") \($0.number)" } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.books.isEmpty { viewModel.load() }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if viewModel.verses.isEmpty {
                    EmptyState(message: "No verses to show.")
                } else {
                    ForEach(viewModel.verses) { verse in
                        (
                            Text("\(verse.number) ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .baselineOffset(4)
                            + Text(verse.text)
                                .font(.body)
                        )
                    }
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    viewModel.previousChapter()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.canGoPrevious)

                Divider().frame(height: 20)

                Button {
                    viewModel.nextChapter()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.canGoNext)
            }
            .padding()
            .background(.bar)
        }
    }
}
