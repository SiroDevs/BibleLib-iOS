//
//  AppConstants.swift
//  BibleLib
//

import Foundation

struct AppConstants {
    static let appTitle = "BibleLib"
    static let appTagline = "Read. Search. Share."

    /// Same static-JSON content backend as the Android app:
    /// info.json, {abbr}/books.json, {abbr}/chapters.json,
    /// {abbr}/verses/{bookId}/{chapter}.json
    static let bibleLibBaseURL = "https://biblive.vercel.app/"
}

struct PrefConstants {
    static let isDataLoaded = "isDataLoadedKey"
    static let hasCompletedSelection = "hasCompletedSelectionKey"
    static let primaryBibleAbbr = "primaryBibleAbbrKey"
    static let installDate = "installDateKey"
    static let lastAppOpenTime = "lastAppOpenTimeKey"
}
