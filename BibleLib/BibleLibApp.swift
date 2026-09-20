//
//  BibleLibApp.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

@main
struct BibleLibApp: App {
    @StateObject private var themeManager = ThemeManager()

    init() {
        _ = DiContainer.shared
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(themeManager)
                .preferredColorScheme({
                    switch themeManager.selectedTheme {
                    case .system: return nil
                    case .light: return .light
                    case .dark: return .dark
                    }
                }())
        }
    }
}
