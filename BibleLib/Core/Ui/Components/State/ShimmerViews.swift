//
//  ShimmerViews.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

private enum Shimmer {
    static let period: TimeInterval = 1.2
    static let travel: CGFloat = 400

    static func offset(at date: Date) -> CGFloat {
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        return max(1, CGFloat(phase) * travel)
    }
}

struct ShimmerBox: View {
    let offset: CGFloat
    var cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [AppColors.surfaceVariant, AppColors.surface, AppColors.surfaceVariant],
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(
                            x: offset / max(geo.size.width, 1),
                            y: offset / max(geo.size.height, 1)
                        )
                    )
                )
        }
    }
}

/// Placeholder rows shown while the Bible list loads (Android: `BibleCardShimmer`).
struct BibleCardShimmer: View {
    var body: some View {
        TimelineView(.animation) { context in
            let offset = Shimmer.offset(at: context.date)

            VStack(spacing: 12) {
                ForEach(0..<10, id: \.self) { _ in
                    HStack(spacing: 12) {
                        ShimmerBox(offset: offset, cornerRadius: 24)
                            .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerBox(offset: offset)
                                .frame(width: 160, height: 18)
                            ShimmerBox(offset: offset)
                                .frame(width: 120, height: 14)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

#Preview {
    BibleCardShimmer()
        .background(AppColors.background)
}
