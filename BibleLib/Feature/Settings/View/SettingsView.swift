//
//  SettingsView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        List {
            Section("Preferences") {
                Button { router.push(.appearanceSettings) } label: {
                    row("Appearance", subtitle: "Theme, reader background", systemImage: "paintbrush")
                }
                Button { router.push(.readingSettings) } label: {
                    row("Reading", subtitle: "Font, size", systemImage: "textformat.size")
                }
            }

            Section("Bibles") {
                Button { router.push(.bibles) } label: {
                    row("Manage Bibles", subtitle: "Primary and secondary Bibles", systemImage: "books.vertical")
                }
            }

            Section("Data") {
                Button { router.push(.dataSettings) } label: {
                    row("App Data", subtitle: "Clear bookmarks, notes, history", systemImage: "externaldrive")
                }
            }

            Section("Support") {
                Button { router.push(.help) } label: {
                    row("Help & Support", subtitle: "Submit a complaint or compliment", systemImage: "questionmark.circle")
                }
            }

            Section("User Manual") {
                Button { router.push(.howItWorks) } label: {
                    row("How It Works", subtitle: "Learn about the features of BibleLib", systemImage: "lightbulb")
                }
            }
        }
        .navigationTitle("Settings")
    }

    private func row(_ title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AppColors.primary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}
