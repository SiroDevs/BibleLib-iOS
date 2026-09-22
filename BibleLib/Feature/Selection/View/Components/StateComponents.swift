//
//  StateComponents.swift
//  BibleLib
//
//  Created by @sirodevs on 22/09/2026.
//

import SwiftUI

struct SavingProgressView: View {
    let progress: Double
    let step: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress) {
                Text("Downloading your primary Bible").font(.headline).foregroundStyle(AppColors.onSurface)
            } currentValueLabel: {
                Text(progress, format: .percent.precision(.fractionLength(0)))
            }
            Text(step)
                .font(.footnote)
                .foregroundStyle(AppColors.onSurfaceVariant)
            Text("The rest of your Bibles will download in the background once your primary Bible is downloaded.")
                .font(.caption)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxHeight: .infinity)
        .animation(.easeOut(duration: 0.3), value: progress)
    }
}

struct DownloadFailedView: View {
    let message: String
    let progress: Double
    let onRestart: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.error)
            Text("Download Failed").font(.title3.weight(.semibold)).foregroundStyle(AppColors.onSurface)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
            ProgressView(value: progress)
            Text("\(Int(progress * 100))% done before it stopped")
                .font(.caption)
                .foregroundStyle(AppColors.onSurfaceVariant)

            HStack(spacing: 12) {
                Button("Restart", action: onRestart)
                    .buttonStyle(.bordered)
                Button(action: onContinue) {
                    Text("Continue").foregroundStyle(AppColors.onPrimary)
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .padding(32)
        .frame(maxHeight: .infinity)
    }
}
