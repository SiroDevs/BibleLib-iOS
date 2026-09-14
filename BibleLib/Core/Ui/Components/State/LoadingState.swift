//
//  LoadingState.swift
//  BibleLib
//
//  Same role as SwahiLib's LoadingState, rebuilt against system colors
//  since this project doesn't have SwahiLib's asset catalog / palette.
//

import SwiftUI

struct LoadingState: View {
    var title: String = ""
    var showProgress: Bool = false
    var progressValue: Double = 0 // 0...1

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)

            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .multilineTextAlignment(.center)
            }

            if showProgress {
                VStack(spacing: 4) {
                    ProgressView(value: progressValue)
                    Text("\(Int(progressValue * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LoadingState(title: "Loading Bibles…", showProgress: true, progressValue: 0.65)
}
