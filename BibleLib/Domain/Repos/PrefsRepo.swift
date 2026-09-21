//
//  PrefsRepo.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

class PrefsRepo {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isDataLoaded: Bool {
        get { userDefaults.bool(forKey: PrefConstants.isDataLoaded) }
        set { userDefaults.set(newValue, forKey: PrefConstants.isDataLoaded) }
    }

    var hasCompletedSelection: Bool {
        get { userDefaults.bool(forKey: PrefConstants.hasCompletedSelection) }
        set { userDefaults.set(newValue, forKey: PrefConstants.hasCompletedSelection) }
    }

    var primaryBibleAbbr: String? {
        get { userDefaults.string(forKey: PrefConstants.primaryBibleAbbr) }
        set { userDefaults.set(newValue, forKey: PrefConstants.primaryBibleAbbr) }
    }

    var lastSyncedAt: Int {
        get { userDefaults.integer(forKey: PrefConstants.lastSyncedAt) }
        set { userDefaults.set(newValue, forKey: PrefConstants.lastSyncedAt) }
    }

    var selectedBibles: [String] {
        get { userDefaults.stringArray(forKey: PrefConstants.selectedBibles) ?? [] }
        set { userDefaults.set(newValue, forKey: PrefConstants.selectedBibles) }
    }

    var lastBible: String {
        get { userDefaults.string(forKey: PrefConstants.lastBible) ?? "" }
        set { userDefaults.set(newValue, forKey: PrefConstants.lastBible) }
    }

    var lastBibleAbbr: String {
        get { userDefaults.string(forKey: PrefConstants.lastBibleAbbr) ?? "" }
        set { userDefaults.set(newValue, forKey: PrefConstants.lastBibleAbbr) }
    }

    var lastBookId: String {
        get { userDefaults.string(forKey: PrefConstants.lastBookId) ?? "" }
        set { userDefaults.set(newValue, forKey: PrefConstants.lastBookId) }
    }

    var lastChapterId: String {
        get { userDefaults.string(forKey: PrefConstants.lastChapterId) ?? "" }
        set { userDefaults.set(newValue, forKey: PrefConstants.lastChapterId) }
    }

    var lastVerseId: String {
        get { userDefaults.string(forKey: PrefConstants.lastVerseId) ?? "" }
        set { userDefaults.set(newValue, forKey: PrefConstants.lastVerseId) }
    }

    var readerFontFamily: String {
        get { userDefaults.string(forKey: PrefConstants.readerFontFamily) ?? "default" }
        set { userDefaults.set(newValue, forKey: PrefConstants.readerFontFamily) }
    }

    var readerBackground: String {
        get { userDefaults.string(forKey: PrefConstants.readerBackground) ?? "default" }
        set { userDefaults.set(newValue, forKey: PrefConstants.readerBackground) }
    }

    var fontSize: Double {
        get {
            let stored = userDefaults.double(forKey: PrefConstants.fontSize)
            return stored == 0 ? ReaderFontSize.standard : stored
        }
        set { userDefaults.set(newValue, forKey: PrefConstants.fontSize) }
    }

    var multiBibleReaderEnabled: Bool {
        get { userDefaults.object(forKey: PrefConstants.multiBibleEnabled) as? Bool ?? true }
        set { userDefaults.set(newValue, forKey: PrefConstants.multiBibleEnabled) }
    }

    var secondaryBibles: [String] {
        get { userDefaults.stringArray(forKey: PrefConstants.secondaryBibles) ?? [] }
        set { userDefaults.set(newValue, forKey: PrefConstants.secondaryBibles) }
    }

    var hasSeenBiblesManagementTip: Bool {
        get { userDefaults.bool(forKey: PrefConstants.hasSeenBiblesManagementTip) }
        set { userDefaults.set(newValue, forKey: PrefConstants.hasSeenBiblesManagementTip) }
    }

    var installDate: Date {
        get { userDefaults.object(forKey: PrefConstants.installDate) as? Date ?? Date() }
        set { userDefaults.set(newValue, forKey: PrefConstants.installDate) }
    }

    var lastAppOpenTime: TimeInterval {
        get { userDefaults.double(forKey: PrefConstants.lastAppOpenTime) }
        set { userDefaults.set(newValue, forKey: PrefConstants.lastAppOpenTime) }
    }

    func updateAppOpenTime() {
        lastAppOpenTime = Date().timeIntervalSince1970
    }

    func resetPrefs() {
        installDate = Date()
        isDataLoaded = false
        hasCompletedSelection = false
        primaryBibleAbbr = nil
        selectedBibles = []
        lastBible = ""
        lastBibleAbbr = ""
        lastBookId = ""
        lastChapterId = ""
        lastVerseId = ""
        secondaryBibles = []
        readerFontFamily = "default"
        readerBackground = "default"
        fontSize = ReaderFontSize.standard
        multiBibleReaderEnabled = true
    }
}
