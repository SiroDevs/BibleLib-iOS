//
//  ScriptureListsView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct ScriptureListsView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(ScriptureListsViewModel.self)
    @EnvironmentObject private var router: AppRouter

    @State private var renaming: ScriptureListSummary?
    @State private var renameText = ""
    @State private var deleting: ScriptureListSummary?

    var body: some View {
        List {
            ForEach(viewModel.lists) { summary in
                Button {
                    router.push(.scriptureListDetail(id: summary.id))
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(summary.list.name).font(.headline).foregroundStyle(.primary)
                        Text(subtitle(summary))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { deleting = summary } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        renameText = summary.list.name
                        renaming = summary
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.isLoading && viewModel.lists.isEmpty {
                EmptyState(message: "No scripture lists yet.\nBuild a queue in the Scripture Opener and save it.")
            }
        }
        .navigationTitle("Scripture Lists")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Rename list", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("List name", text: $renameText)
            Button("Save") {
                if let renaming { viewModel.rename(renaming.id, to: renameText) }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
        .alert("Delete list?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Delete", role: .destructive) {
                if let deleting { viewModel.delete(deleting.id) }
                deleting = nil
            }
            Button("Cancel", role: .cancel) { deleting = nil }
        } message: {
            Text("This removes \"\(deleting?.list.name ?? "")\" and its scriptures.")
        }
        .onAppear { viewModel.load() }
    }

    private func subtitle(_ summary: ScriptureListSummary) -> String {
        let count = summary.itemCount == 1 ? "1 scripture" : "\(summary.itemCount) scriptures"
        return summary.firstReference.isEmpty ? count : "\(count) · starts at \(summary.firstReference)"
    }
}

struct ScriptureListDetailView: View {
    let listId: Int64

    @StateObject private var viewModel = DiContainer.shared.resolve(ScriptureListDetailViewModel.self)
    @EnvironmentObject private var router: AppRouter

    @State private var showRename = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section {
                ForEach(viewModel.items) { item in
                    Button {
                        if let target = viewModel.open(startingAt: item) { router.openReader(target) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.reference).font(.headline).foregroundStyle(.primary)
                                Text(item.bibleName).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            } footer: {
                Text("Tap a scripture to read the list from there.")
            }

            if !viewModel.items.isEmpty {
                Section {
                    Button {
                        if let target = viewModel.open() { router.openReader(target) }
                    } label: {
                        Label("Read This List", systemImage: "book")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.list?.name ?? "Scripture List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        renameText = viewModel.list?.name ?? ""
                        showRename = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Rename list", isPresented: $showRename) {
            TextField("List name", text: $renameText)
            Button("Save") { viewModel.rename(to: renameText) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete list?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { viewModel.delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the list and its scriptures.")
        }
        .onChange(of: viewModel.deleted) { deleted in
            if deleted { router.pop() }
        }
        .onAppear { viewModel.load(id: listId) }
    }
}
