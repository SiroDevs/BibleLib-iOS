//
//  BibleTheme.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

private struct CardSurface: ViewModifier {
    let isSelected: Bool
    let isDisabled: Bool

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: AppSizes.cornerRadius) }

    func body(content: Content) -> some View {
        content
            .padding(AppSizes.padding)
            .background {
                ZStack {
                    shape.fill(AppColors.surface)
                    if isSelected {
                        shape.fill(AppColors.primaryContainer)
                    } else if isDisabled {
                        shape.fill(AppColors.surfaceVariant.opacity(0.5))
                    } else {
                        shape.fill(AppColors.surfaceTint.opacity(AppSizes.tonalTint))
                    }
                }
                .shadow(
                    color: AppColors.shadow.opacity(0.2),
                    radius: isSelected ? 4 : 1,
                    y: isSelected ? 2 : 1
                )
            }
            .overlay {
                if isSelected {
                    shape.strokeBorder(AppColors.primary, lineWidth: AppSizes.borderWidth)
                }
            }
            .contentShape(shape)
    }
}

extension View {
    func cardSurface(isSelected: Bool = false, isDisabled: Bool = false) -> some View {
        modifier(CardSurface(isSelected: isSelected, isDisabled: isDisabled))
    }
}

struct AppGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var minimumCardWidth: CGFloat { sizeClass == .regular ? 210 : 160 }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumCardWidth), spacing: AppSizes.gap)],
            spacing: AppSizes.gap
        ) {
            content
        }
    }
}
