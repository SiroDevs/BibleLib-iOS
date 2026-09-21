//
//  BibleItem.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

enum BibleItemLayout {
    case row    // single item in a group: full width
    case grid   // 2+ items in a group: one cell of BibleGrid
}

struct BibleItem: View {
    typealias Layout = BibleItemLayout

    let bible: BibleInfoDTO
    let isSelected: Bool
    let isDisabled: Bool
    var layout: Layout = .row
    let onTap: () -> Void

    var body: some View {
        BibleItemView(
            abbreviation: bible.abbreviation,
            name: bible.name,
            subtitle: bible.description.isEmpty ? bible.language.name : bible.description,
            language: bible.language.name,
            isSelected: isSelected,
            isDisabled: isDisabled,
            layout: layout,
            onTap: onTap
        )
    }
}

/// Mirrors the Android `BibleListItem`. Row and grid share one card and one layout;
/// the grid only reserves two lines for the name because its cells are narrower.
struct BibleItemView: View {
    let abbreviation: String
    let name: String
    let subtitle: String
    let language: String
    let isSelected: Bool
    let isDisabled: Bool
    var layout: BibleItemLayout = .row
    let onTap: () -> Void

    private var isGrid: Bool { layout == .grid }

    var body: some View {
        Button(action: onTap) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .bibleCardSurface(isSelected: isSelected, isDisabled: isDisabled)
                .scaleEffect(isSelected ? BibleMetrics.selectedScale : 1)
        }
        // .plain: inside scrolling containers the default style dims/highlights the whole label
        // and the card draws its own selected / disabled states.
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(BibleMetrics.selectionSpring, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var content: some View {
        HStack(spacing: BibleMetrics.spacing) {
            leading

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))                          // titleSmall
                    .foregroundStyle(MaterialColors.onSurface.opacity(isDisabled ? 0.4 : 1))
                    .multilineTextAlignment(.leading)
                    .lineLimit(isGrid ? 2 : 1, reservesSpace: isGrid)
                Text(subtitle)
                    .font(.caption)                                                // bodySmall
                    .foregroundStyle(MaterialColors.onSurface.opacity(0.55))
                    .lineLimit(1)
                Text("\(language) Bible".uppercased())
                    .font(.caption2)                                               // labelSmall
                    .foregroundStyle(MaterialColors.secondary)
                    .lineLimit(1)
            }
        }
    }

    /// Abbreviation badge, replaced by a checkmark when selected. Both use the same
    /// square so the text never shifts sideways when the selection changes.
    private var leading: some View {
        ZStack {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(MaterialColors.primary)
                    .transition(.scale)
            } else {
                Text(String(abbreviation.uppercased().prefix(3)))
                    .font(.subheadline.weight(.bold))                              // labelLarge
                    .foregroundStyle(MaterialColors.onSurfaceVariant)
                    .frame(width: BibleMetrics.badgeSize, height: BibleMetrics.badgeSize)
                    .background(
                        MaterialColors.surfaceVariant,
                        in: RoundedRectangle(cornerRadius: BibleMetrics.cornerRadius)
                    )
                    .transition(.scale)
            }
        }
        .frame(width: BibleMetrics.badgeSize, height: BibleMetrics.badgeSize)
    }
}

struct BibleItemPlaceholder: View {
    var body: some View {
        HStack(spacing: BibleMetrics.spacing) {
            RoundedRectangle(cornerRadius: BibleMetrics.cornerRadius)
                .frame(width: BibleMetrics.badgeSize, height: BibleMetrics.badgeSize)
            VStack(alignment: .leading, spacing: 2) {
                Text("King James Version").font(.subheadline.weight(.semibold))
                Text("The classic English translation").font(.caption)
                Text("ENGLISH BIBLE").font(.caption2)
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(reason: .placeholder)
        .bibleCardSurface()
    }
}
