//
//  AppTextStyle.swift
//  BibleLib
//
//  Created by @sirodevs on 13/09/2026.
//

import SwiftUI

enum AppTextStyle {
    case headlineSmall   // 24 / 32
    case titleLarge      // 22 / 28  (Typography.kt: Normal)
    case titleMedium     // 16 / 24
    case titleSmall      // 14 / 20
    case bodyMedium      // 14 / 20
    case bodySmall       // 12 / 16
    case labelLarge      // 14 / 20
    case labelSmall      // 11 / 16  (Typography.kt: Medium)

    var size: CGFloat {
        switch self {
        case .headlineSmall: return 24
        case .titleLarge: return 22
        case .titleMedium: return 16
        case .titleSmall, .bodyMedium, .labelLarge: return 14
        case .bodySmall: return 12
        case .labelSmall: return 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .headlineSmall, .titleLarge, .bodyMedium, .bodySmall: return .regular
        case .titleMedium, .titleSmall, .labelLarge, .labelSmall: return .medium
        }
    }

    var tracking: CGFloat {
        switch self {
        case .headlineSmall, .titleLarge: return 0
        case .titleMedium: return 0.15
        case .titleSmall, .labelLarge: return 0.1
        case .bodyMedium: return 0.25
        case .bodySmall: return 0.4
        case .labelSmall: return 0.5
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .headlineSmall: return 32
        case .titleLarge: return 28
        case .titleMedium: return 24
        case .titleSmall, .bodyMedium, .labelLarge: return 20
        case .bodySmall, .labelSmall: return 16
        }
    }
}

extension View {
    func textStyle(_ style: AppTextStyle, weight: Font.Weight? = nil) -> some View {
        self
            .font(.system(size: style.size, weight: weight ?? style.weight))
            .tracking(style.tracking)
    }
}
