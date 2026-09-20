//
//  BiblesView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct BiblesView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(BiblesViewModel.self)

    @State private var showPrimaryPicker = false
    @State private var showSelection = false
    @State private var showLimitAlert = false

    private static let managementInfo = """
    You can add a Bible to the Multi-Bible Reader by swiping it to the right from “Other Bibles” — swipe it right again to remove it as a secondary translation.

    To delete a Bible from your device entirely, swipe it to the left and confirm.

    Want more Bibles than what's shown here? Tap “Change Selection” below to go back to the Bible picker and add (or remove) translations from your library.
    """

    var body: some View {
        List {
            primarySection
            multiBibleSection
            if !viewModel.secondary.isEmpty { secondarySection }
            if !viewModel.others.isEmpty { othersSection }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                showSelection = true
            } label: {
                Label("Change Selection", systemImage: "square.grid.2x2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.bar)
        }
        .navigationTitle("Manage Bibles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.secondary.count > 1 { EditButton() }
                Button { viewModel.showManagementInfo = true } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("How Bible management works")
            }
        }
        .sheet(isPresented: $showPrimaryPicker) {
            primaryPicker
        }
        .fullScreenCover(isPresented: $showSelection) {
            SelectionView(
                onFinished: { _ in
                    showSelection = false
                    viewModel.load()
                },
                onCancel: { showSelection = false }
            )
        }
        .alert("Would you like to know how to manage your Bibles?", isPresented: $viewModel.showFirstOpenPrompt) {
            Button("Show Me") { viewModel.dismissFirstOpenPrompt(showInfoNext: true) }
            Button("Not Now", role: .cancel) { viewModel.dismissFirstOpenPrompt(showInfoNext: false) }
        } message: {
            Text("Learn how to add or remove Bibles from the Multi-Bible Reader, and how to add more translations to your library.")
        }
        .alert("Managing your Bibles", isPresented: $viewModel.showManagementInfo) {
            Button("Got It", role: .cancel) {}
        } message: {
            Text(Self.managementInfo)
        }
        .alert(
            "Remove \(viewModel.pendingDelete?.name ?? "")?",
            isPresented: Binding(
                get: { viewModel.pendingDelete != nil },
                set: { if !$0 { viewModel.pendingDelete = nil } }
            )
        ) {
            Button("Remove", role: .destructive) { viewModel.confirmDelete() }
            Button("Cancel", role: .cancel) { viewModel.pendingDelete = nil }
        } message: {
            Text("This deletes all downloaded content for this Bible from your device. This can't be undone.")
        }
        .alert("Secondary Bible limit reached", isPresented: $showLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can show up to \(MultiBibleLimits.maxSecondary) secondary Bibles under each verse.")
        }
        .onAppear { viewModel.load() }
        .task(id: viewModel.hasPendingDownloads) {
            while viewModel.hasPendingDownloads && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if Task.isCancelled { break }
                viewModel.load()
            }
        }
    }

    private var primarySection: some View {
        Section {
            if let primary = viewModel.primary {
                Button { showPrimaryPicker = true } label: {
                    bibleRow(primary, subtitlePrefix: "PRIMARY", trailing: {
                        Text("Change").font(.subheadline).foregroundStyle(AppColors.primary)
                    })
                }
                .buttonStyle(.plain)
            } else {
                Text("No primary Bible set yet.").foregroundStyle(.secondary)
            }
        } header: {
            Text("Primary Bible")
        }
    }

    private var multiBibleSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.multiBibleEnabled },
                set: { viewModel.setMultiBibleEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Multi-Bible Reader")
                    Text("Read parallel translations alongside your primary text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var secondarySection: some View {
        Section {
            ForEach(viewModel.secondary) { bible in
                bibleRow(bible, subtitlePrefix: nil, trailing: { EmptyView() })
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.toggleSecondary(bible.abbreviation)
                        } label: {
                            Label("Remove", systemImage: "minus.circle")
                        }
                        .tint(.orange)
                    }
            }
            .onMove { viewModel.moveSecondary(from: $0, to: $1) }
        } header: {
            Text(viewModel.secondary.count == 1 ? "1 secondary Bible" : "\(viewModel.secondary.count) secondary Bibles")
        } footer: {
            Text("Swipe left to remove from the Multi-Bible Reader.")
        }
    }

    private var othersSection: some View {
        Section {
            ForEach(viewModel.others) { bible in
                bibleRow(bible, subtitlePrefix: nil, trailing: { EmptyView() })
                    .swipeActions(edge: .leading) {
                        if bible.isDownloaded {
                            Button {
                                if !viewModel.toggleSecondary(bible.abbreviation) { showLimitAlert = true }
                            } label: {
                                Label("Add", systemImage: "plus.circle")
                            }
                            .tint(AppColors.primary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.pendingDelete = bible
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        } header: {
            Text("Other Bibles")
        } footer: {
            Text("Swipe right to set as secondary, left to delete.")
        }
    }

    private func bibleRow<Trailing: View>(
        _ bible: Bible,
        subtitlePrefix: String?,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Text(String(bible.abbreviation.uppercased().prefix(3)))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppColors.primary, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(bible.name).font(.body)
                HStack(spacing: 4) {
                    Text("\(bible.languageName.uppercased()) BIBLE" + (subtitlePrefix.map { " • \($0)" } ?? ""))
                    statusText(for: bible)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if bible.downloadFailed {
                    HStack(spacing: 8) {
                        Button("Restart") { viewModel.restartDownload(bible.abbreviation) }
                        Button("Continue") { viewModel.retryDownload(bible.abbreviation) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 2)
                } else if !bible.isDownloaded {
                    ProgressView(value: bible.downloadProgress)
                        .tint(AppColors.primary)
                }
            }

            Spacer(minLength: 0)
            trailing()
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func statusText(for bible: Bible) -> some View {
        if bible.downloadFailed {
            Text("· Download failed").foregroundStyle(.red)
        } else if !bible.isDownloaded {
            Text("· \(Int(bible.downloadProgress * 100))%")
        } else {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        }
    }

    private var primaryPicker: some View {
        NavigationStack {
            List(viewModel.bibles.filter(\.isDownloaded)) { bible in
                Button {
                    viewModel.setPrimaryBible(bible.abbreviation)
                    showPrimaryPicker = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bible.name).foregroundStyle(.primary)
                            Text("\(bible.languageName.uppercased()) BIBLE")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if bible.abbreviation == viewModel.primaryAbbr {
                            Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Choose primary Bible")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { showPrimaryPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
