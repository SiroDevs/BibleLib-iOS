//
//  DataSettingsView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct DataSettingsView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(SettingsViewModel.self)
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Manage Your Data") {
                clearButton("Clear All Bookmarks", systemImage: "bookmark", target: .bookmarks)
                clearButton("Clear All Notes", systemImage: "note.text", target: .notes)
                clearButton("Clear All History", systemImage: "clock.arrow.circlepath", target: .history)
                clearButton("Clear Searches", systemImage: "magnifyingglass", target: .searches)
            }

            Section {
                Button(role: .destructive) {
                    viewModel.pendingClear = .allData
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Deletes every downloaded Bible, bookmark, note, history entry, search, and preference — including your theme and reading settings — and restarts the app at Bible selection. This can't be undone.")
            }
        }
        .navigationTitle("App Data")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            viewModel.pendingClear?.title ?? "",
            isPresented: Binding(
                get: { viewModel.pendingClear != nil },
                set: { if !$0 { viewModel.pendingClear = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                if viewModel.confirmClear() {
                    themeManager.selectedTheme = .system
                }
            }
            Button("Cancel", role: .cancel) { viewModel.pendingClear = nil }
        } message: {
            Text(viewModel.pendingClear?.message ?? "")
        }
    }

    private func clearButton(_ title: String, systemImage: String, target: ClearTarget) -> some View {
        Button {
            viewModel.pendingClear = target
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
