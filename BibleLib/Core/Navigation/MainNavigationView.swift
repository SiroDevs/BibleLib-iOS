//
//  MainNavigationView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//


import SwiftUI

struct MainNavigationView: View {
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            ReaderView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .environmentObject(router)
        .tint(AppColors.primary)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .notes(let request): NotesView(request: request)
        case .history: HistoryView()
        case .bookmarksNotes: BookmarkNotesView()
        case .bibles: BiblesView()
        case .search: SearchView()
        case .scriptureOpener(let abbr, let name): ScriptureOpenerView(bibleAbbr: abbr, bibleName: name)
        case .scriptureLists: ScriptureListsView()
        case .scriptureListDetail(let id): ScriptureListDetailView(listId: id)
        case .settings: SettingsView()
        case .appearanceSettings: AppearanceSettingsView()
        case .readingSettings: ReadingSettingsView()
        case .dataSettings: DataSettingsView()
        case .howItWorks: HowItWorksView()
        case .help: HelpView()
        }
    }
}
