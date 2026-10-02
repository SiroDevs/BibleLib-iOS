//
//  BookPickerSheet.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct BookPickerSheet: View {
    @ObservedObject var viewModel: ReaderViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var testament = 0

    private static let oldTestamentCount = 39

    private var ordered: [Book] {
        viewModel.books.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var visibleBooks: [Book] {
        let tab = testament == 0
            ? Array(ordered.prefix(Self.oldTestamentCount))
            : Array(ordered.dropFirst(Self.oldTestamentCount))
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return tab }
        return tab.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.nameLong.localizedCaseInsensitiveContains(trimmed)
                || $0.abbreviation.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List(visibleBooks) { book in
                Button {
                    viewModel.select(book)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(String(book.id.prefix(3)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppColors.secondary)
                            .frame(width: 36, alignment: .leading)
                        Text(book.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if book.id == viewModel.activeBook?.id {
                            Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if visibleBooks.isEmpty { EmptyState(message: "No matching books") }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("Testament", selection: $testament) {
                    Text("Old Testament").tag(0)
                    Text("New Testament").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search books")
            .navigationTitle("Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
