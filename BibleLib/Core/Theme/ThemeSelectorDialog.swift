//
//  ThemeSelectorDialog.swift
//  BibleLib
//
//  Port of Android's ThemeSelectorDialog (a Material 3 AlertDialog with a radio
//  list). Present it as an overlay above the screen and drive it with a Bool:
//
//      .overlay { if showThemeDialog { ThemeSelectorDialog(...) } }
//

import SwiftUI

struct ThemeSelectorDialog: View {
    let onDismiss: () -> Void
    let onThemeSelected: (AppThemeMode) -> Void

    @State private var selectedTheme: AppThemeMode

    init(
        current: AppThemeMode,
        onDismiss: @escaping () -> Void,
        onThemeSelected: @escaping (AppThemeMode) -> Void
    ) {
        _selectedTheme = State(initialValue: current)
        self.onDismiss = onDismiss
        self.onThemeSelected = onThemeSelected
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 0) {
                Text("Choose Theme")
                    .textStyle(.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(AppThemeMode.allCases) { mode in
                        row(for: mode)
                    }
                }
                .padding(.bottom, 24)

                HStack(spacing: 8) {
                    Spacer(minLength: 0)

                    Button("Cancel", action: onDismiss)
                        .buttonStyle(.appText)

                    Button("OKAY") {
                        onThemeSelected(selectedTheme)
                        onDismiss()
                    }
                    .buttonStyle(.appText)
                }
            }
            .padding(24)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(AppColors.surfaceContainerHigh)
            )
        }
        .accessibilityAddTraits(.isModal)
    }

    private func row(for mode: AppThemeMode) -> some View {
        let isSelected = selectedTheme == mode

        return Button {
            selectedTheme = mode
        } label: {
            HStack(spacing: 0) {
                RadioIndicator(isSelected: isSelected)
                    .frame(width: 48, height: 48)

                Text(mode.displayName)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .padding(.leading, 8)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Material RadioButton: 20pt ring, 10pt dot when selected.
private struct RadioIndicator: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? AppColors.primary : AppColors.onSurfaceVariant, lineWidth: 2)

            if isSelected {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(width: 20, height: 20)
    }
}

#Preview {
    ThemeSelectorDialog(current: .system, onDismiss: {}, onThemeSelected: { _ in })
}
