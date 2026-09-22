//
//  OptionsSheets.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct QuickSettingsSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefConstants.fontSize) private var fontSize = ReaderFontSize.standard
    @AppStorage(PrefConstants.multiBibleEnabled) private var multiBible = true

    var body: some View {
        NavigationStack {
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

                Section("Font size: \(Int(fontSize)) pt") {
                    HStack(spacing: 12) {
                        Image(systemName: "textformat.size.smaller")
                        Slider(value: $fontSize, in: ReaderFontSize.minimum...ReaderFontSize.maximum, step: 2)
                        Image(systemName: "textformat.size.larger")
                    }
                    .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("Multi-Bible Reader", isOn: $multiBible)
                } footer: {
                    Text("Show your secondary Bibles under each verse.")
                }
            }
            .navigationTitle("Quick Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct HighlightColorSheet: View {
    let onChoose: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    ForEach(Array(HighlightColors.hexes.enumerated()), id: \.offset) { index, hex in
                        Button { onChoose(hex) } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 40, height: 40)
                                .overlay(Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(HighlightColors.names[index])
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .navigationTitle("Choose a highlight color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.height(170)])
    }
}
