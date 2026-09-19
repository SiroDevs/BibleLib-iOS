//
//  BibleListItem.swift
//  BibleLib
//
//  Port of Android's BibleListItem card: 10pt corners, 45pt abbreviation badge,
//  name / description / "LANGUAGE BIBLE" column, check mark when selected.
//

import SwiftUI

struct BibleListItem: View {
    let name: String
    let description: String
    let abbreviation: String
    let language: String
    let isSelected: Bool
    let isDisabled: Bool
    let onClick: () -> Void

    private var containerColor: Color {
        if isSelected { return AppColors.primaryContainer }
        if isDisabled { return AppColors.surfaceVariant.opacity(0.5) }
        return AppColors.surface
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10)

        HStack(spacing: 5) {
            Text(String(abbreviation.uppercased().prefix(3)))
                .textStyle(.labelLarge, weight: .bold)
                .foregroundStyle(isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant)
                .frame(width: 45, height: 45)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? AppColors.primary : AppColors.surfaceVariant)
                )

            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .textStyle(.titleSmall, weight: .semibold)
                    .foregroundStyle(AppColors.onSurface.opacity(isDisabled ? 0.4 : 1))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(height: AppTextStyle.titleSmall.lineHeight, alignment: .leading)

                Text(description.isEmpty ? language : description)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.onSurface.opacity(0.55))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(height: AppTextStyle.bodySmall.lineHeight, alignment: .leading)

                Text("\(language) bible".uppercased())
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(height: AppTextStyle.labelSmall.lineHeight, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 22, height: 22)
                    .transition(.scale)
                    .accessibilityLabel("Selected")
            }
        }
        .padding(5)
        .frame(maxWidth: .infinity)
        .background(shape.fill(containerColor))
        .overlay {
            if isSelected {
                shape.strokeBorder(AppColors.primary, lineWidth: 2)
            }
        }
        .compositingGroup()
        .shadow(
            color: Color.black.opacity(isSelected ? 0.22 : 0.16),
            radius: isSelected ? 4 : 1.5,
            x: 0,
            y: isSelected ? 2 : 1
        )
        .scaleEffect(isSelected ? 0.97 : 1)
        .animation(.spring(response: 0.16, dampingFraction: 0.5), value: isSelected)
        .contentShape(shape)
        .onTapGesture {
            if !isDisabled { onClick() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    VStack(spacing: 12) {
        BibleListItem(name: "King James Version", description: "The classic 1611 English translation",
                      abbreviation: "KJV", language: "English", isSelected: true, isDisabled: false, onClick: {})
        BibleListItem(name: "Biblia Takatifu", description: "Open Kiswahili Contemporary Version (Neno) 2015",
                      abbreviation: "SW", language: "Swahili", isSelected: false, isDisabled: false, onClick: {})
        BibleListItem(name: "New International Version", description: "New International Version 2011",
                      abbreviation: "NIV", language: "English", isSelected: false, isDisabled: true, onClick: {})
    }
    .padding(16)
    .background(AppColors.background)
}
