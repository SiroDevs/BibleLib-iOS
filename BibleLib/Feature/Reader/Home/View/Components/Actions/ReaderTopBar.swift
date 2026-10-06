//
//  ReaderTopBar.swift
//  BibleLib
//
//  Created by @sirodevs on 02/10/2026.
//

import SwiftUI

struct ReaderTopBar: View {
    let bibleAbbr: String
    let bibleName: String
    let bookName: String
    let chapterNumber: String
    let onTapBible: () -> Void
    let onTapBook: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Button(action: onTapBible) {
                Label("\(bibleAbbr.uppercased()) · \(bibleName)", systemImage: "chevron.down")
                    .labelStyle(TrailingIconLabelStyle())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())

            Button(action: onTapBook) {
                Label("\(bookName) \(chapterNumber)", systemImage: "chevron.down")
                    .labelStyle(TrailingIconLabelStyle())
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.font(.system(size: 9, weight: .bold))
        }
    }
}
