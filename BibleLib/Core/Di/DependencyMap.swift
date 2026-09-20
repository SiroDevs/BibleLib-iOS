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

        container.register(SyncScheduler.self) { resolver in
            SyncScheduler(
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!,
                prefsRepo: resolver.resolve(PrefsRepo.self)!
            )
        }.inObjectScope(.container)

        container.register(SplashViewModel.self) { resolver in
            SplashViewModel(
                prefsRepo: resolver.resolve(PrefsRepo.self)!,
                syncScheduler: resolver.resolve(SyncScheduler.self)!
            )
        }

        container.register(SelectionViewModel.self) { resolver in
            SelectionViewModel(
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!,
                prefsRepo: resolver.resolve(PrefsRepo.self)!,
                syncScheduler: resolver.resolve(SyncScheduler.self)!
            )
        }

        // MARK: - User data

        container.register(UserDataManager.self) { resolver in
            UserDataManager(coreDataManager: resolver.resolve(CoreDataManager.self)!)
        }.inObjectScope(.container)

        container.register(AnnotationRepo.self) { resolver in
            AnnotationRepo(data: resolver.resolve(UserDataManager.self)!)
        }.inObjectScope(.container)

        container.register(TrackingRepo.self) { resolver in
            TrackingRepo(data: resolver.resolve(UserDataManager.self)!)
        }.inObjectScope(.container)

        container.register(ScriptureRepo.self) { resolver in
            ScriptureRepo(data: resolver.resolve(UserDataManager.self)!)
        }.inObjectScope(.container)

        container.register(ScriptureQueueRepo.self) { _ in
            ScriptureQueueRepo()
        }.inObjectScope(.container)

        // MARK: - View models

        container.register(ReaderViewModel.self) { resolver in
            ReaderViewModel(
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!,
                prefsRepo: resolver.resolve(PrefsRepo.self)!,
                annotationRepo: resolver.resolve(AnnotationRepo.self)!,
                trackingRepo: resolver.resolve(TrackingRepo.self)!,
                queueRepo: resolver.resolve(ScriptureQueueRepo.self)!
            )
        }

        container.register(NotesViewModel.self) { resolver in
            NotesViewModel(annotationRepo: resolver.resolve(AnnotationRepo.self)!)
        }

        container.register(BookmarkNotesViewModel.self) { resolver in
            BookmarkNotesViewModel(
                annotationRepo: resolver.resolve(AnnotationRepo.self)!,
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!
            )
        }

        container.register(HistoryViewModel.self) { resolver in
            HistoryViewModel(trackingRepo: resolver.resolve(TrackingRepo.self)!)
        }

        container.register(SearchViewModel.self) { resolver in
            SearchViewModel(
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!,
                prefsRepo: resolver.resolve(PrefsRepo.self)!,
                trackingRepo: resolver.resolve(TrackingRepo.self)!
            )
        }

        container.register(BiblesViewModel.self) { resolver in
            BiblesViewModel(
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!,
                prefsRepo: resolver.resolve(PrefsRepo.self)!,
                syncScheduler: resolver.resolve(SyncScheduler.self)!
            )
        }

        container.register(SettingsViewModel.self) { resolver in
            SettingsViewModel(
                prefsRepo: resolver.resolve(PrefsRepo.self)!,
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!,
                annotationRepo: resolver.resolve(AnnotationRepo.self)!,
                trackingRepo: resolver.resolve(TrackingRepo.self)!,
                scriptureRepo: resolver.resolve(ScriptureRepo.self)!,
                syncScheduler: resolver.resolve(SyncScheduler.self)!
            )
        }

        container.register(ScriptureOpenerViewModel.self) { resolver in
            ScriptureOpenerViewModel(
                bibleRepo: resolver.resolve(BibleRepoProtocol.self)!,
                scriptureRepo: resolver.resolve(ScriptureRepo.self)!,
                queueRepo: resolver.resolve(ScriptureQueueRepo.self)!,
                prefsRepo: resolver.resolve(PrefsRepo.self)!
            )
        }

        container.register(ScriptureListsViewModel.self) { resolver in
            ScriptureListsViewModel(scriptureRepo: resolver.resolve(ScriptureRepo.self)!)
        }

        container.register(ScriptureListDetailViewModel.self) { resolver in
            ScriptureListDetailViewModel(
                scriptureRepo: resolver.resolve(ScriptureRepo.self)!,
                queueRepo: resolver.resolve(ScriptureQueueRepo.self)!
            )
        }
    }
}
