//
//  BibleTheme.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

/// Sizes and spacing taken from the Android `BibleListItem` (1dp = 1pt).
enum BibleMetrics {
    static let cornerRadius: CGFloat = 10      // RoundedCornerShape(10.dp)
    static let badgeSize: CGFloat = 45         // Box.size(45.dp)
    static let padding: CGFloat = 5            // Row.padding(5.dp)
    static let spacing: CGFloat = 5            // Arrangement.spacedBy(5.dp)
    static let borderWidth: CGFloat = 2        // BorderStroke(2.dp, primary) when selected
    static let selectedScale: CGFloat = 0.97   // animateFloatAsState(0.97f) when selected

    /// Space between cards, and between the cards and the screen edge.
    static let gap: CGFloat = 8
    static let screenPadding: CGFloat = 8

    /// Compose: spring(dampingRatio = MediumBouncy) -> ~0.5 damping, default (medium) stiffness.
    static let selectionSpring = Animation.spring(response: 0.2, dampingFraction: 0.5)
}

/// The Material 3 colour roles the Android item uses, mapped onto iOS.
/// `primary` / `secondary` come from `AppColors`, so they follow the selected theme.
/// The neutral roles use system colours so light and dark mode keep working.
enum MaterialColors {
    static var primary: Color { AppColors.primary }
    static var secondary: Color { AppColors.secondary }

    /// Tonal tint of primary (Material's primaryContainer) - used for the selected card.
    static var primaryContainer: Color { AppColors.primary.opacity(0.18) }

    static var background: Color { Color(.systemGroupedBackground) }
    static var surface: Color { Color(.secondarySystemGroupedBackground) }
    static var surfaceVariant: Color { Color(.secondarySystemFill) }

    static var onSurface: Color { Color.primary }
    static var onSurfaceVariant: Color { Color.secondary }
}

/// Android's `Card`: surface colour, 10pt corners, elevation shadow,
/// primaryContainer + 2pt primary border when selected, dimmed surfaceVariant when disabled.
private struct BibleCardSurface: ViewModifier {
    let isSelected: Bool
    let isDisabled: Bool

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: BibleMetrics.cornerRadius) }

    func body(content: Content) -> some View {
        content
            .padding(BibleMetrics.padding)
            .background {
                // Layered (not a translucent fill) so the shadow never shows through the container.
                ZStack {
                    shape.fill(MaterialColors.surface)
                    if isSelected {
                        shape.fill(MaterialColors.primaryContainer)
                    } else if isDisabled {
                        shape.fill(MaterialColors.surfaceVariant.opacity(0.5))
                    }
                }
                .shadow(
                    color: .black.opacity(0.15),
                    radius: isSelected ? 4 : 1,          // cardElevation 4dp / 1dp
                    y: isSelected ? 2 : 1
                )
            }
            .overlay {
                if isSelected {
                    shape.strokeBorder(MaterialColors.primary, lineWidth: BibleMetrics.borderWidth)
                }
            }
            .contentShape(shape)
    }
}

extension View {
    func bibleCardSurface(isSelected: Bool = false, isDisabled: Bool = false) -> some View {
        modifier(BibleCardSurface(isSelected: isSelected, isDisabled: isDisabled))
    }
}

/// Fluid grid. Adaptive columns fill whatever width the view is given, so the count follows the
/// window rather than the device: 2 across on iPhone, 3 / 4 / 5 / 6 on iPad as the width grows
/// (portrait -> landscape, 11" -> 13"), and back to 2 in a narrow Split View or Slide Over.
struct BibleGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// Minimum card width: 160pt gives 2 columns on any phone, 210pt gives
    /// 3 at 744pt, 4 at ~1030pt and 6 at ~1370pt (iPad widths).
    private var minimumCardWidth: CGFloat { sizeClass == .regular ? 210 : 160 }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumCardWidth), spacing: BibleMetrics.gap)],
            spacing: BibleMetrics.gap
        ) {
            content
        }
    }
}
