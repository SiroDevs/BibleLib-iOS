//
//  SplashViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

final class SplashViewModel: ObservableObject {
    @Published var isInitialized = false

    private let netUtils: NetworkUtils
    let prefsRepo: PrefsRepo
    private let syncScheduler: SyncScheduler

    init(netUtils: NetworkUtils = .shared, prefsRepo: PrefsRepo, syncScheduler: SyncScheduler) {
        self.netUtils = netUtils
        self.prefsRepo = prefsRepo
        self.syncScheduler = syncScheduler
    }

    func initialize() {
        Task {
            _ = await netUtils.checkNetworkAvailability()
            prefsRepo.updateAppOpenTime()
            // Pick up any Bible downloads that were interrupted when the app last closed.
            syncScheduler.resumeIncompleteDownloads()
            await MainActor.run {
                isInitialized = true
            }
        }
    }
}
