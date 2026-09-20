//
//  RetryErrorState.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

struct RetryErrorState: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.error)
                .frame(width: 48, height: 48)

            Text(message)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
                .multilineTextAlignment(.center)

            if let onRetry {
                Button(action: onRetry) {
                    Text("Retry")
                }
                .buttonStyle(.appOutlined)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RetryErrorState(message: "Could not load Bibles. Please check your connection and try again.") {}
        .background(AppColors.background)
}
