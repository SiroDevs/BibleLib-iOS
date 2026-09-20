//
//  AppProgress.swift
//  BibleLib
//
//  Created by @sirodevs on 15/09/2026.
//

import SwiftUI

struct AppCircularProgress: View {
    let progress: Double
    var size: CGFloat = 96
    var strokeWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.surfaceVariant, lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(AppColors.primary, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(strokeWidth / 2)
        .frame(width: size, height: size)
    }
}

struct AppLinearProgress: View {
    let progress: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.surfaceVariant)
                Capsule()
                    .fill(AppColors.primary)
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
}
