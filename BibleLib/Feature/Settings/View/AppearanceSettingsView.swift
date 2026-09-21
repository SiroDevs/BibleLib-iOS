//
//  AppearanceSettingsView.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage(PrefConstants.readerBackground) private var backgroundId = "default"

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $themeManager.selectedTheme) {
                    ForEach(AppThemeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Reader Background") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 16)], spacing: 16) {
                    ForEach(ReaderBackgrounds.all) { option in
                        Button {
                            backgroundId = option.id
                        } label: {
                            swatch(option)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func swatch(_ option: ReaderBackgroundOption) -> some View {
        let isSelected = backgroundId == option.id

        return VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12)
                .fill(option.background)
                .frame(height: 52)
                .overlay { Text("Aa").font(.headline).foregroundStyle(option.textColor) }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? AppColors.primary : Color(.separator), lineWidth: isSelected ? 3 : 1)
                }
            Text(option.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
