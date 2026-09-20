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
