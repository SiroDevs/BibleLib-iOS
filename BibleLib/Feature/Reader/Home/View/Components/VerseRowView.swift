//
//  VerseRowView.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct ParallelText: Identifiable {
    let abbr: String
    let text: String
    var id: String { abbr }
}

struct VerseRowView: View {
    let verse: VerseDisplay
    let font: ReaderFontOption
    let fontSize: Double
    let highlightQuery: String?
    let parallelTexts: [ParallelText]
    let isBookmarked: Bool
    let hasNote: Bool
    let textColor: Color
    let secondaryTextColor: Color

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    private var size: CGFloat { CGFloat(fontSize) * typeScale }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            primaryText
                .lineSpacing(size * 0.35)
                .foregroundStyle(textColor)

            ForEach(parallelTexts) { item in
                parallelText(abbr: item.abbr, text: item.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var primaryText: some View {
        var line = Text("\(verse.number) ")
            .font(font.font(size: size * 0.72, weight: .bold))
            .foregroundColor(AppColors.primary)

        if isBookmarked {
            line = line + Text(Image(systemName: "bookmark.fill"))
                .font(.system(size: size * 0.7))
                .foregroundColor(AppColors.primary)
            line = line + Text(" ")
        }

        line = line + Text(Self.highlighted(verse.text, query: highlightQuery, color: AppColors.secondaryContainer))
            .font(font.font(size: size))

        if hasNote {
            line = line + Text(" ")
            line = line + Text(Image(systemName: "note.text"))
                .font(.system(size: size * 0.7))
                .foregroundColor(AppColors.secondary)
        }
        return line
    }

    private func parallelText(abbr: String, text: String) -> some View {
        (
            Text("[\(abbr.uppercased())] ")
                .font(font.font(size: size * 0.65, weight: .bold))
                .foregroundColor(AppColors.secondary)
            + Text(Self.highlighted(text, query: highlightQuery, color: AppColors.secondaryContainer))
                .font(font.font(size: size * 0.85))
        )
        .lineSpacing(size * 0.3)
        .foregroundStyle(secondaryTextColor)
    }

    static func highlighted(_ text: String, query: String?, color: Color) -> AttributedString {
        var attributed = AttributedString(text)
        guard let query, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return attributed }

        var searchStart = attributed.startIndex
        while searchStart < attributed.endIndex,
              let range = attributed[searchStart...].range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) {
            attributed[range].backgroundColor = color
            attributed[range].inlinePresentationIntent = .stronglyEmphasized
            searchStart = range.upperBound
        }
        return attributed
    }
}
