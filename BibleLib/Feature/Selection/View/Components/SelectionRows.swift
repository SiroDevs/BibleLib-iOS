//
//  SelectionRows.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct SelectionSection: Identifiable {
    struct Header {
        let key: String
        let title: String
        let total: Int
    }

    struct CountryFilter {
        let continentKey: String
        let options: [FilterOption]
        let selected: String
    }

    let id: String
    var header: Header?
    var filter: CountryFilter?
    var items: [Selectable<BibleInfoDTO>] = []

    var usesGrid: Bool { items.count > 1 }

    static func make(from entries: [GridEntry]) -> [SelectionSection] {
        var sections: [SelectionSection] = []

        for entry in entries {
            switch entry {
            case .header(let key, let title, let total):
                sections.append(SelectionSection(id: key, header: Header(key: key, title: title, total: total)))
            case .countryFilterStrip(_, let continentKey, let options, let selected):
                guard !sections.isEmpty else { continue }
                sections[sections.count - 1].filter = CountryFilter(continentKey: continentKey, options: options, selected: selected)
            case .item(_, let bible, _):
                if sections.isEmpty { sections.append(SelectionSection(id: "all")) }
                sections[sections.count - 1].items.append(bible)
            }
        }
        return sections
    }
}

struct SavingProgressView: View {
    let progress: Double
    let step: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress) {
                Text("Downloading your primary Bible").font(.headline)
            } currentValueLabel: {
                Text(progress, format: .percent.precision(.fractionLength(0)))
            }
            Text(step)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("The rest of your Bibles will download in the background once your primary Bible is downloaded.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxHeight: .infinity)
        .animation(.easeOut(duration: 0.3), value: progress)
    }
}

struct DownloadFailedView: View {
    let message: String
    let progress: Double
    let onRestart: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Download Failed").font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            ProgressView(value: progress)
            Text("\(Int(progress * 100))% done before it stopped")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Restart", action: onRestart)
                    .buttonStyle(.bordered)
                Button("Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .padding(32)
        .frame(maxHeight: .infinity)
    }
}

#if DEBUG
private struct PreviewBible: Identifiable {
    let id: String   // abbreviation
    let name: String
    let subtitle: String
    let language: String
    var selected = false
    var disabled = false
}

private let previewBibles: [PreviewBible] = [
    .init(id: "KJV", name: "King James Version", subtitle: "The classic 1611 English translation", language: "English", selected: true),
    .init(id: "NIV", name: "New International Version", subtitle: "New International Version 2011", language: "English"),
    .init(id: "ESV", name: "English Standard Version", subtitle: "Essentially literal translation", language: "English"),
    .init(id: "NKJ", name: "New King James Version", subtitle: "Modern update of the KJV", language: "English"),
    .init(id: "NLT", name: "New Living Translation", subtitle: "Thought-for-thought translation", language: "English"),
    .init(id: "CSB", name: "Christian Standard Bible", subtitle: "Optimal equivalence", language: "English"),
    .init(id: "SW", name: "Biblia Takatifu", subtitle: "Open Kiswahili Contemporary Version (Neno) 2015", language: "Swahili", disabled: true),
    .init(id: "SUV", name: "Swahili Union Version", subtitle: "Biblia Habari Njema", language: "Swahili", disabled: true),
    .init(id: "ASV", name: "American Standard Version", subtitle: "1901 revision of the KJV", language: "English"),
    .init(id: "WEB", name: "World English Bible", subtitle: "Public domain modern English", language: "English"),
    .init(id: "GNB", name: "Good News Bible", subtitle: "Today's English Version", language: "English"),
    .init(id: "RSV", name: "Revised Standard Version", subtitle: "1952 revision of the ASV", language: "English"),
]

private func previewCard(_ bible: PreviewBible, layout: BibleItemLayout) -> some View {
    BibleItemView(
        abbreviation: bible.id, name: bible.name, subtitle: bible.subtitle, language: bible.language,
        isSelected: bible.selected, isDisabled: bible.disabled, layout: layout, onTap: {}
    )
}

private struct PreviewGrid: View {
    var count = previewBibles.count

    var body: some View {
        ScrollView {
            BibleGrid {
                ForEach(previewBibles.prefix(count)) { previewCard($0, layout: .grid) }
            }
            .padding(BibleMetrics.screenPadding)
        }
        .background(MaterialColors.background)
        .environmentObject(ThemeManager())
    }
}

#Preview("Row") {
    ScrollView {
        VStack(spacing: BibleMetrics.gap) {
            ForEach(previewBibles.prefix(3)) { previewCard($0, layout: .row) }
        }
        .padding(BibleMetrics.screenPadding)
    }
    .background(MaterialColors.background)
    .environmentObject(ThemeManager())
}

#Preview("Grid - iPhone (2 columns)") {
    PreviewGrid(count: 6)
}

#Preview("Grid - iPhone, dark") {
    PreviewGrid(count: 6)
        .preferredColorScheme(.dark)
}

#Preview("Grouped: grid + row") {
    ScrollView {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                BibleGrid {
                    ForEach(previewBibles.prefix(3)) { previewCard($0, layout: .grid) }
                }
                .padding(.horizontal, BibleMetrics.screenPadding)
                .padding(.bottom, BibleMetrics.gap)
            } header: {
                Text("English").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BibleMetrics.screenPadding)
                    .padding(.vertical, 6)
            }
            Section {
                previewCard(previewBibles[6], layout: .row)
                    .padding(.horizontal, BibleMetrics.screenPadding)
            } header: {
                Text("Swahili").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BibleMetrics.screenPadding)
                    .padding(.vertical, 6)
            }
        }
    }
    .background(MaterialColors.background)
    .environmentObject(ThemeManager())
}

// Regular width = iPad. Widths are typical window widths; the size class is forced because
// a fixed-layout preview doesn't derive it from the width.
#Preview("Grid - iPad portrait (3 columns)", traits: .fixedLayout(width: 744, height: 500)) {
    PreviewGrid()
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("Grid - iPad 13\" portrait (4 columns)", traits: .fixedLayout(width: 1032, height: 500)) {
    PreviewGrid()
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("Grid - iPad 13\" landscape (6 columns)", traits: .fixedLayout(width: 1376, height: 400)) {
    PreviewGrid()
        .environment(\.horizontalSizeClass, .regular)
}
#endif
