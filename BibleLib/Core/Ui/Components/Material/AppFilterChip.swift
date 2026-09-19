//
//  AppFilterChip.swift
//  BibleLib
//
//  Material 3 FilterChip look-alike: 32pt tall, 8pt corners, outlined when
//  unselected, secondaryContainer when selected. Like Compose it reserves a
//  48pt-tall touch target around the 32pt chip.
//

import SwiftUI

struct AppFilterChip: View {
    let label: String
    let isSelected: Bool
    /// Show a leading check mark while selected (Compose: `leadingIcon`).
    var showsCheckWhenSelected: Bool = false
    let action: () -> Void

    private var hasLeadingIcon: Bool { isSelected && showsCheckWhenSelected }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if hasLeadingIcon {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 16, height: 16)
                }
                Text(label)
                    .textStyle(.labelLarge)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant)
            .padding(.leading, hasLeadingIcon ? 8 : 16)
            .padding(.trailing, 16)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppColors.secondaryContainer : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.clear : AppColors.outlineVariant, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .frame(minHeight: 48)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
