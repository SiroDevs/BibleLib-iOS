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

    init(netUtils: NetworkUtils = .shared, prefsRepo: PrefsRepo) {
        self.netUtils = netUtils
        self.prefsRepo = prefsRepo
    }

    func initialize() {
        Task {
            _ = await netUtils.checkNetworkAvailability()
            prefsRepo.updateAppOpenTime()
            await MainActor.run {
                isInitialized = true
            }
        }
    }
}
