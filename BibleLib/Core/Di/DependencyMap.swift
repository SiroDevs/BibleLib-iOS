//
//  DependencyMap.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Swinject

struct DependencyMap {
    static func registerDependencies(in container: Container) {
        container.register(PrefsRepo.self) { _ in
            PrefsRepo()
        }.inObjectScope(.container)

        container.register(CoreDataManager.self) { _ in
            CoreDataManager.shared
        }.inObjectScope(.container)

        container.register(BibleLibApiServiceProtocol.self) { _ in
            BibleLibApiService()
        }.inObjectScope(.container)

        container.register(BibleDataManager.self) { resolver in
            BibleDataManager(coreDataManager: resolver.resolve(CoreDataManager.self)!)
        }.inObjectScope(.container)

        container.register(BibleRepoProtocol.self) { resolver in
            BibleRepo(
                api: resolver.resolve(BibleLibApiServiceProtocol.self)!,
                bibleData: resolver.resolve(BibleDataManager.self)!
            )
        }.inObjectScope(.container)

        container.register(SplashViewModel.self) { resolver in
            SplashViewModel(prefsRepo: resolver.resolve(PrefsRepo.self)!)
        }

        container.register(SelectionViewModel.self) { resolver in
            SelectionViewModel(
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!,
                prefsRepo: resolver.resolve(PrefsRepo.self)!
            )
        }

        container.register(ReaderViewModel.self) { (resolver: Resolver, bibleAbbr: String) in
            ReaderViewModel(bibleAbbr: bibleAbbr, bibleRepo: resolver.resolve(BibleRepoProtocol.self)!)
        }
    }
}
