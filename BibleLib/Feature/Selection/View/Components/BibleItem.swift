//
//  BibleItem.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

enum BibleItemLayout {
    case row
    case grid
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
                .cardSurface(isSelected: isSelected, isDisabled: isDisabled)
                .scaleEffect(isSelected ? AppSizes.selectedScale : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(AppSizes.selectionSpring, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var content: some View {
        HStack(spacing: AppSizes.spacing) {
            leading

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.onSurface.opacity(isDisabled ? 0.4 : 1))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.onSurface.opacity(0.55))
                    .lineLimit(1)
                Text("\(language) Bible".uppercased())
                    .font(.caption2)
                    .foregroundStyle(AppColors.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var leading: some View {
        ZStack {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.primary)
                    .transition(.scale)
            } else {
                Text(String(abbreviation.uppercased().prefix(3)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: AppSizes.badgeSize, height: AppSizes.badgeSize)
                    .background(
                        AppColors.surfaceVariant,
                        in: RoundedRectangle(cornerRadius: AppSizes.cornerRadius)
                    )
                    .transition(.scale)
            }
        }
        .frame(width: AppSizes.badgeSize, height: AppSizes.badgeSize)
    }
}

struct BibleItemPlaceholder: View {
    var body: some View {
        HStack(spacing: AppSizes.spacing) {
            RoundedRectangle(cornerRadius: AppSizes.cornerRadius)
                .frame(width: AppSizes.badgeSize, height: AppSizes.badgeSize)
            VStack(alignment: .leading, spacing: 2) {
                Text("King James Version").font(.subheadline.weight(.semibold))
                Text("The classic English translation").font(.caption)
                Text("ENGLISH BIBLE").font(.caption2)
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(reason: .placeholder)
        .cardSurface()
    }
}
