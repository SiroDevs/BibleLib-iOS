//
//  ThemeManager.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light Theme"
        case .dark: return "Dark Theme"
        }
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppThemeMode.system.rawValue

    var selectedTheme: AppThemeMode {
        get { AppThemeMode(rawValue: selectedThemeRaw) ?? .system }
        set { selectedThemeRaw = newValue.rawValue }
    }
}
