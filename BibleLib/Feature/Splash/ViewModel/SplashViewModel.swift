//
//  SplashViewModel.swift
//  BibleLib
//
//  Trimmed down from SwahiLib's SplashViewModel — no subscription check,
//  BibleLib doesn't have one.
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
