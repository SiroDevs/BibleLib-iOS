//
//  AppTopBar.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

struct AppTopBar<Actions: View>: View {
    let title: String
    var tagline: String?
    var showGoBack: Bool
    var titleMaxLines: Int
    var onNavIconClick: (() -> Void)?
    private let actions: () -> Actions

    init(
        title: String,
        tagline: String? = nil,
        showGoBack: Bool = false,
        titleMaxLines: Int = 1,
        onNavIconClick: (() -> Void)? = nil,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.title = title
        self.tagline = tagline
        self.showGoBack = showGoBack
        self.titleMaxLines = titleMaxLines
        self.onNavIconClick = onNavIconClick
        self.actions = actions
    }

    var body: some View {
        HStack(spacing: 0) {
            if showGoBack {
                AppIconButton(systemName: "arrow.left", accessibilityLabel: "Back") {
                    onNavIconClick?()
                }
                .padding(.leading, 4)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .textStyle(.titleLarge)
                    .lineLimit(titleMaxLines)
                    .truncationMode(.tail)

                if let tagline, !tagline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(tagline.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.onSurface)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.leading, showGoBack ? 4 : 16)

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                actions()
            }
        }
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, minHeight: 64)
        .foregroundStyle(AppColors.onPrimaryContainer)
        .background(AppColors.onPrimary.ignoresSafeArea(edges: .top))
    }
}

extension AppTopBar where Actions == EmptyView {
    init(
        title: String,
        tagline: String? = nil,
        showGoBack: Bool = false,
        titleMaxLines: Int = 1,
        onNavIconClick: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            tagline: tagline,
            showGoBack: showGoBack,
            titleMaxLines: titleMaxLines,
            onNavIconClick: onNavIconClick,
            actions: { EmptyView() }
        )
    }
}

/// Material IconButton: a 24pt icon centered in a 48pt touch target.
struct AppIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .regular))
                .frame(width: 24, height: 24)
                .frame(width: 48, height: 48)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    VStack(spacing: 0) {
        AppTopBar(
            title: "BibleLib: Multi-Bible Reader",
            tagline: "2 / 7 bibles selected"
        ) {
            AppIconButton(systemName: "arrow.clockwise", accessibilityLabel: "Refresh") {}
            AppIconButton(systemName: "circle.lefthalf.filled", accessibilityLabel: "Theme") {}
        }
        Spacer()
    }
    .background(AppColors.background)
}
