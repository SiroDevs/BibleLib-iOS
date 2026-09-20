//
//  ReaderCustomization.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//


import SwiftUI

struct ReaderFontOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    fileprivate let family: String?
    fileprivate let design: Font.Design

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let family {
            return Font.custom(family, size: size).weight(weight)
        }
        return Font.system(size: size, weight: weight, design: design)
    }
}

enum ReaderFonts {
    static let all: [ReaderFontOption] = [
        ReaderFontOption(id: "default", displayName: "San Francisco (System)", family: nil, design: .default),
        ReaderFontOption(id: "serif", displayName: "New York (Serif)", family: nil, design: .serif),
        ReaderFontOption(id: "rounded", displayName: "SF Rounded", family: nil, design: .rounded),
        ReaderFontOption(id: "mono_space", displayName: "SF Mono (System)", family: nil, design: .monospaced),
        ReaderFontOption(id: "georgia", displayName: "Georgia", family: "Georgia", design: .default),
        ReaderFontOption(id: "palatino", displayName: "Palatino", family: "Palatino", design: .default),
        ReaderFontOption(id: "iowan", displayName: "Iowan Old Style", family: "Iowan Old Style", design: .default),
        ReaderFontOption(id: "baskerville", displayName: "Baskerville", family: "Baskerville", design: .default),
        ReaderFontOption(id: "charter", displayName: "Charter", family: "Charter", design: .default),
        ReaderFontOption(id: "avenir", displayName: "Avenir Next", family: "Avenir Next", design: .default),
        ReaderFontOption(id: "helvetica", displayName: "Helvetica Neue", family: "Helvetica Neue", design: .default),
        ReaderFontOption(id: "gill_sans", displayName: "Gill Sans", family: "Gill Sans", design: .default),
        ReaderFontOption(id: "optima", displayName: "Optima", family: "Optima", design: .default),
    ]

    static func byId(_ id: String) -> ReaderFontOption {
        all.first { $0.id == id } ?? all[0]
    }
}

struct ReaderBackgroundOption: Identifiable {
    let id: String
    let displayName: String
    let swatch: Color
    fileprivate let colors: [Color]?
    let isDark: Bool?

    var background: AnyShapeStyle {
        guard let colors else { return AnyShapeStyle(AppColors.surface) }
        return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
    }

    var textColor: Color {
        switch isDark {
        case .some(true): return Color(white: 0.92)
        case .some(false): return Color(red: 0.16, green: 0.13, blue: 0.10)
        case .none: return .primary
        }
    }

    var secondaryTextColor: Color {
        switch isDark {
        case .some(true): return Color(white: 0.92).opacity(0.7)
        case .some(false): return Color(red: 0.16, green: 0.13, blue: 0.10).opacity(0.7)
        case .none: return .secondary
        }
    }
}

enum ReaderBackgrounds {
    private static func rgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let all: [ReaderBackgroundOption] = [
        ReaderBackgroundOption(id: "default", displayName: "Default", swatch: .white, colors: nil, isDark: nil),
        ReaderBackgroundOption(id: "cream", displayName: "Cream", swatch: rgb(0xF7EFDD), colors: [rgb(0xFAF3E4), rgb(0xF3E9D2)], isDark: false),
        ReaderBackgroundOption(id: "sepia", displayName: "Sepia", swatch: rgb(0xEADDC7), colors: [rgb(0xEFE3CC), rgb(0xE4D3AF)], isDark: false),
        ReaderBackgroundOption(id: "parchment", displayName: "Parchment", swatch: rgb(0xEFE6D2), colors: [rgb(0xF3ECDA), rgb(0xE8DBB8)], isDark: false),
        ReaderBackgroundOption(id: "mint", displayName: "Mint", swatch: rgb(0xE3F1EA), colors: [rgb(0xEAF6F0), rgb(0xDCEEE3)], isDark: false),
        ReaderBackgroundOption(id: "sky", displayName: "Sky", swatch: rgb(0xE2EEF7), colors: [rgb(0xEAF3FA), rgb(0xD9E9F5)], isDark: false),
        ReaderBackgroundOption(id: "blush", displayName: "Blush", swatch: rgb(0xF7E4E0), colors: [rgb(0xFBEDE9), rgb(0xF4DAD3)], isDark: false),
        ReaderBackgroundOption(id: "night", displayName: "Night", swatch: rgb(0x15181C), colors: [rgb(0x1B1E23), rgb(0x0F1114)], isDark: true),
        ReaderBackgroundOption(id: "charcoal", displayName: "Charcoal", swatch: rgb(0x262524), colors: [rgb(0x2C2B29), rgb(0x1C1B1A)], isDark: true),
        ReaderBackgroundOption(id: "forest", displayName: "Forest", swatch: rgb(0x16211B), colors: [rgb(0x1B2A22), rgb(0x10190F)], isDark: true),
    ]

    static func byId(_ id: String) -> ReaderBackgroundOption {
        all.first { $0.id == id } ?? all[0]
    }
}

enum HighlightColors {
    static let hexes = ["#FFF59D", "#A5D6A7", "#90CAF9", "#F48FB1", "#FFCC80", "#CE93D8"]
    static let names = ["Yellow", "Green", "Blue", "Pink", "Orange", "Purple"]
}

extension Color {
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let int = UInt32(value, radix: 16) else { return nil }
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}
