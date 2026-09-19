//
//  DiContainer.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Swinject

final class DiContainer {
    static let shared = DiContainer()
    let container: Container

    private init() {
        container = Container()
        DependencyMap.registerDependencies(in: container)
        validateDependencies()
    }

    private func validateDependencies() {
        let dependencies: [() -> Any?] = [
            { self.container.resolve(PrefsRepo.self) },
            { self.container.resolve(CoreDataManager.self) },
            { self.container.resolve(BibleLibApiServiceProtocol.self) },
            { self.container.resolve(BibleDataManager.self) },
            { self.container.resolve(BibleRepoProtocol.self) },
            { self.container.resolve(SyncScheduler.self) },
            { self.container.resolve(SplashViewModel.self) },
            { self.container.resolve(SelectionViewModel.self) },
        ]

        for resolve in dependencies {
            guard resolve() != nil else {
                fatalError("One or more dependencies are not registered in the container.")
            }
        }
        print("✅ All dependencies are successfully registered.")
    }
}

extension DiContainer {
    func resolve<T>(_ type: T.Type) -> T {
        guard let dependency = container.resolve(type) else {
            fatalError("Failed to resolve dependency: \(type)")
        }
        return dependency
    }

    func resolve<T, Arg>(_ type: T.Type, argument: Arg) -> T {
        guard let dependency = container.resolve(type, argument: argument) else {
            fatalError("Failed to resolve dependency: \(type) with argument: \(argument)")
        }
        return dependency
    }
}
