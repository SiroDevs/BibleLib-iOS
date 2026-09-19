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

    /// True once the Bible list (info.json) has been fetched at least once.
    var isDataLoaded: Bool {
        get { userDefaults.bool(forKey: PrefConstants.isDataLoaded) }
        set { userDefaults.set(newValue, forKey: PrefConstants.isDataLoaded) }
    }

    /// True once the user has picked + downloaded at least one Bible and
    /// chosen a primary. Mirrors Android's "selection completed" flag —
    /// this is what Splash checks to route to Selection vs. the Reader.
    var hasCompletedSelection: Bool {
        get { userDefaults.bool(forKey: PrefConstants.hasCompletedSelection) }
        set { userDefaults.set(newValue, forKey: PrefConstants.hasCompletedSelection) }
    }

    var primaryBibleAbbr: String? {
        get { userDefaults.string(forKey: PrefConstants.primaryBibleAbbr) }
        set { userDefaults.set(newValue, forKey: PrefConstants.primaryBibleAbbr) }
    }

    /// Abbreviations of every Bible the user has chosen, in selection order
    /// (the first one is the primary). Mirrors Android's `selectedBibles`.
    var selectedBibles: [String] {
        get { userDefaults.stringArray(forKey: PrefConstants.selectedBibles) ?? [] }
        set { userDefaults.set(newValue, forKey: PrefConstants.selectedBibles) }
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
    }
}
