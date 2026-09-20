//
//  AppColors.swift
//  BibleLib
//
//  Created by @sirodevs on 13/09/2026.
//

import SwiftUI
import UIKit

enum AppColors {
    static let primary = Color("primary1")
    static let onPrimary = Color("onPrimary")
    static let primaryContainer = Color("primaryContainer")
    static let onPrimaryContainer = Color("onPrimaryContainer")

    static let secondary = Color("secondary1")
    static let onSecondary = Color("onSecondary")
    static let secondaryContainer = Color("secondaryContainer")
    static let onSecondaryContainer = Color("onSecondaryContainer")

    static let tertiary = Color("tertiary")
    static let onTertiary = Color("onTertiary")
    static let tertiaryContainer = Color("tertiaryContainer")
    static let onTertiaryContainer = Color("onTertiaryContainer")

    static let error = Color("error")
    static let onError = Color("onError")
    static let errorContainer = Color("errorContainer")
    static let onErrorContainer = Color("onErrorContainer")

    static let background = Color("background1")
    static let onBackground = Color("onBackground")
    static let surface = Color("surface")
    static let onSurface = Color("onSurface")
    static let surfaceVariant = Color("surfaceVariant")
    static let onSurfaceVariant = Color("onSurfaceVariant")
    static let surfaceTint = Color("surfaceTint")

    static let outline = Color("outline")
    static let outlineVariant = Color("outlineVariant")

    static let inverseSurface = Color("inverseSurface")
    static let inverseOnSurface = Color("inverseOnSurface")
    static let inversePrimary = Color("inversePrimary")

    static let scrim = Color("scrim")
    static let shadow = Color("shadow")

    /// Android's `lightColorScheme(...)` / `darkColorScheme(...)` don't override
    /// the surface-container roles, so Compose falls back to the Material 3
    /// baseline values. Material's AlertDialog paints itself with
    /// `surfaceContainerHigh`, so the theme dialog needs the same fallback to
    /// look identical.
    static let surfaceContainerHigh = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x2B / 255, green: 0x29 / 255, blue: 0x30 / 255, alpha: 1)
            : UIColor(red: 0xEC / 255, green: 0xE6 / 255, blue: 0xF0 / 255, alpha: 1)
    })
}
