//
//  ReaderSheets.swift
//  BibleLib
//
//  Sheets presented from the reader: book picker, chapter picker, primary Bible
//  picker, quick settings and the highlight color picker.
//

import SwiftUI

// MARK: - Books

struct BookPickerSheet: View {
    let books: [Book]
    let activeBookId: String?
    let onSelect: (Book) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var testament = 0

    private static let oldTestamentCount = 39

    private var ordered: [Book] { books.sorted { $0.sortOrder < $1.sortOrder } }

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
                    onSelect(book)
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
                        if book.id == activeBookId {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Chapters

struct ChapterPickerSheet: View {
    let chapters: [Chapter]
    let activeChapterId: String?
    let onSelect: (Chapter) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 8)], spacing: 8) {
                    ForEach(chapters) { chapter in
                        let isActive = chapter.id == activeChapterId
                        Button {
                            onSelect(chapter)
                            dismiss()
                        } label: {
                            Text(chapter.number)
                                .font(.body.weight(isActive ? .bold : .regular))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(isActive ? AppColors.onPrimaryContainer : Color.primary)
                                .background(
                                    isActive ? AppColors.primaryContainer : Color(.secondarySystemFill),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Jump to a Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Primary Bible

struct BibleSelectorSheet: View {
    let bibles: [Bible]
    let activeAbbr: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(bibles.filter(\.isDownloaded)) { bible in
                Button {
                    onSelect(bible.abbreviation)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(String(bible.abbreviation.uppercased().prefix(3)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppColors.primary, in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bible.name).foregroundStyle(.primary)
                            Text("\(bible.languageName.uppercased()) · \(bible.description)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if bible.abbreviation == activeAbbr {
                            Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Primary Bible")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        BiblesView()
                    } label: {
                        Label("Manage Bibles", systemImage: "books.vertical")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Quick settings

struct QuickSettingsSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefConstants.fontSize) private var fontSize = ReaderFontSize.standard
    @AppStorage(PrefConstants.multiBibleEnabled) private var multiBible = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme") {
                    Picker("Theme", selection: Binding(
                        get: { themeManager.selectedTheme },
                        set: { themeManager.selectedTheme = $0 }
                    )) {
                        Text("System").tag(AppThemeMode.system)
                        Text("Light").tag(AppThemeMode.light)
                        Text("Dark").tag(AppThemeMode.dark)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("Font size: \(Int(fontSize)) pt") {
                    HStack(spacing: 12) {
                        Image(systemName: "textformat.size.smaller")
                        Slider(value: $fontSize, in: ReaderFontSize.minimum...ReaderFontSize.maximum, step: 2)
                        Image(systemName: "textformat.size.larger")
                    }
                    .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("Multi-Bible Reader", isOn: $multiBible)
                } footer: {
                    Text("Show your secondary Bibles under each verse.")
                }
            }
            .navigationTitle("Quick Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Highlight colors

struct HighlightColorSheet: View {
    let onChoose: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    ForEach(Array(HighlightColors.hexes.enumerated()), id: \.offset) { index, hex in
                        Button { onChoose(hex) } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 40, height: 40)
                                .overlay(Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(HighlightColors.names[index])
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .navigationTitle("Choose a highlight color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.height(170)])
    }
}
