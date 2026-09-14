//
//  SelectionView.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

struct SelectionView: View {
    @StateObject private var viewModel: SelectionViewModel = DiContainer.shared.resolve(SelectionViewModel.self)
    @State private var navigateToReader = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.uiState {
                case .loading(let message) where viewModel.bibles.isEmpty:
                    LoadingState(title: message ?? "")
                case .error(let message) where viewModel.bibles.isEmpty:
                    ErrorState(message: message) {
                        Task { await viewModel.loadAvailableBibles() }
                    }
                default:
                    listContent
                }
            }
            .navigationTitle("Choose your Bibles")
            .task {
                if viewModel.bibles.isEmpty {
                    await viewModel.loadAvailableBibles()
                }
            }
            .navigationDestination(isPresented: $navigateToReader) {
                if let abbr = viewModel.primaryAbbr {
                    ReaderView(bibleAbbr: abbr)
                }
            }
        }
    }

    private var listContent: some View {
        List {
            if case .error(let message) = viewModel.uiState {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }

            ForEach(viewModel.bibles) { item in
                row(for: item)
            }
        }
        .safeAreaInset(edge: .bottom) {
            downloadButton
        }
    }

    private func row(for item: Selectable<Bible>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.data.name).font(.headline)
                Text(item.data.languageName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let progress = viewModel.downloadProgress[item.data.abbreviation] {
                    ProgressView(value: progress.value) {
                        Text(progress.step).font(.caption)
                    }
                }
            }
            Spacer()
            Button {
                viewModel.setPrimary(item.data.abbreviation)
            } label: {
                Image(systemName: item.data.abbreviation == viewModel.primaryAbbr ? "star.fill" : "star")
                    .foregroundColor(item.data.abbreviation == viewModel.primaryAbbr ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isSelected ? .accentColor : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleSelection(item.data.abbreviation) }
    }

    private var downloadButton: some View {
        Button {
            Task {
                await viewModel.downloadSelected()
                if case .saved = viewModel.uiState {
                    navigateToReader = true
                }
            }
        } label: {
            Text(viewModel.isDownloading ? "Downloading…" : "Download selected")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .background(.bar)
        .disabled(!viewModel.bibles.contains(where: \.isSelected) || viewModel.isDownloading)
    }
}

#Preview {
    SelectionView()
}
