//
//  BibleLibApp.swift
//  BibleLib
//
//  Step 1 bare-minimum scaffold, built on the same architectural footprint
//  as SwahiLib (Core/Di, Domain, Data, Feature) so later features slot in
//  the same way. No RevenueCat/notifications yet — BibleLib doesn't need
//  them for the core reading loop.
//

import SwiftUI

@main
struct BibleLibApp: App {
    @StateObject private var themeManager = ThemeManager()

    init() {
        // Resolving the container at launch also runs DiContainer's
        // dependency validation, so a missing registration crashes
        // immediately at startup instead of surfacing later.
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
