//
//  SelectionComponents.swift
//  BibleLib
//
//  Ports of the composables in Android's selection/view/components/Components.kt.
//

import SwiftUI

struct BibleSavingProgress: View {
    let progress: Double
    let step: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AppCircularProgress(progress: progress, size: 96, strokeWidth: 6)
                Text("\(Int(progress * 100))%")
                    .textStyle(.titleMedium)
                    .foregroundStyle(AppColors.onSurface)
            }

            Text("Downloading your primary Bible")
                .textStyle(.titleMedium)
                .foregroundStyle(AppColors.onSurface)
                .padding(.top, 24)

            Text(step)
                .textStyle(.bodySmall)
                .foregroundStyle(AppColors.onSurface.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            AppLinearProgress(progress: progress)
                .padding(.top, 24)

            Text("The rest of your Bibles will download in the background once your primary Bible is downloaded.")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.onSurface.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.3), value: progress)
    }
}

struct DownloadFailedState: View {
    let message: String
    let progress: Double
    let onContinue: () -> Void
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 50))
                .foregroundStyle(AppColors.error)
                .frame(width: 56, height: 56)

            Text("DOWNLOAD FAILED")
                .textStyle(.titleMedium, weight: .bold)
                .foregroundStyle(AppColors.error)
                .padding(.top, 16)

            Text(message)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.onSurface.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            AppLinearProgress(progress: progress)
                .padding(.top, 20)

            Text("\(Int(progress * 100))% done before it stopped")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.onSurface.opacity(0.6))
                .padding(.top, 6)

            HStack(spacing: 12) {
                Button(action: onRestart) {
                    Text("RESTART").frame(maxWidth: .infinity)
                }
                .buttonStyle(.appOutlined)

                Button(action: onContinue) {
                    Text("CONTINUE").frame(maxWidth: .infinity)
                }
                .buttonStyle(.appFilled)
            }
            .padding(.top, 28)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GroupHeader: View {
    let title: String
    let totalInGroup: Int
    let expanded: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text(title)
                        .textStyle(.titleSmall, weight: .semibold)
                        .foregroundStyle(AppColors.onBackground)
                        .lineLimit(1)

                    Text(totalInGroup == 1 ? "\(totalInGroup) bible" : "\(totalInGroup) bibles")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.onSurface.opacity(0.6))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.onBackground)
                    .frame(width: 24, height: 24)
                    .accessibilityLabel(expanded ? "Collapse" : "Expand")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(AppColors.surfaceVariant.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .padding(.leading, 5)
        .padding(.trailing, 5)
        .padding(.bottom, 5)
    }
}

struct GroupingFilmStrip: View {
    let selected: GroupingMode
    let onSelected: (GroupingMode) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(GroupingMode.allCases) { mode in
                    AppFilterChip(
                        label: mode.label,
                        isSelected: mode == selected,
                        showsCheckWhenSelected: true
                    ) {
                        onSelected(mode)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
    }
}

struct FilterChipStrip: View {
    let options: [FilterOption]
    let selected: String
    let onSelected: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(options, id: \.name) { option in
                    AppFilterChip(
                        label: "\(option.name) (\(option.count))",
                        isSelected: option.name == selected
                    ) {
                        onSelected(option.name)
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
        }
    }
}

struct ProceedBar: View {
    let canProceed: Bool
    let onProceed: () -> Void

    var body: some View {
        Button(action: onProceed) {
            Text("Continue").frame(maxWidth: .infinity)
        }
        .buttonStyle(AppButtonStyle(kind: .filled, cornerRadius: 12))
        .disabled(!canProceed)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}
