//
//  AppearanceSettingsView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(SettingsViewModel.self)
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: Binding(
                    get: { themeManager.selectedTheme },
                    set: { themeManager.selectedTheme = $0 }
                )) {
                    Text("System").tag(AppThemeMode.system)
                    Text("Light").tag(AppThemeMode.light)
                    Text("Dark").tag(AppThemeMode.dark)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Reader Background") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 16)], spacing: 16) {
                    ForEach(ReaderBackgrounds.all) { option in
                        Button {
                            viewModel.setReaderBackground(option.id)
                        } label: {
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(option.background)
                                    .frame(height: 52)
                                    .overlay {
                                        Text("Aa")
                                            .font(.headline)
                                            .foregroundStyle(option.textColor)
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                viewModel.readerBackgroundId == option.id ? AppColors.primary : Color.primary.opacity(0.15),
                                                lineWidth: viewModel.readerBackgroundId == option.id ? 3 : 1
                                            )
                                    }
                                Text(option.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
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
}
