//
//  AppConstants.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct AppConstants {
    static let appTitle = "BibleLib"
    static let appCredits = "© Siro Devs"
    static let bibleLibBaseURL = "https://biblive.vercel.app/v2/"
}

struct PrefConstants {
    static let isDataLoaded = "isDataLoadedKey"
    static let hasCompletedSelection = "hasCompletedSelectionKey"
    static let primaryBibleAbbr = "primaryBibleAbbrKey"
    static let selectedBibles = "selectedBiblesKey"
    static let lastSyncedAt = "lastSyncedAtKey"
    static let installDate = "installDateKey"
    static let lastAppOpenTime = "lastAppOpenTimeKey"
    static let lastBible = "lastBibleKey"
    static let lastBibleAbbr = "lastBibleAbbrKey"
    static let lastBookId = "lastBookIdKey"
    static let lastChapterId = "lastChapterIdKey"
    static let lastVerseId = "lastVerseIdKey"
    static let readerFontFamily = "readerFontFamilyKey"
    static let readerBackground = "readerBackgroundKey"
    static let fontSize = "fontSizeKey"
    static let multiBibleEnabled = "multiBibleEnabledKey"
    static let secondaryBibles = "secondaryBiblesKey"
    static let hasSeenBiblesManagementTip = "hasSeenBiblesManagementTipKey"
}

/// Reader font size range and default, in points (Android: AppFonts).
enum ReaderFontSize {
    static let minimum: Double = 12
    static let maximum: Double = 32
    static let standard: Double = 18
}

/// Secondary-Bible limits for the multi-Bible reader (Android: PrefsRepo companion).
enum MultiBibleLimits {
    static let defaultSecondary = 2
    static let maxSecondary = 5
}
