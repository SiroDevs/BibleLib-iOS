//
//  AppRouter.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct ReaderTarget: Hashable {
    var bibleAbbr: String
    var bookId: String = ""
    var chapterId: String = ""
    var verseId: String = ""
    var searchQuery: String = ""
    var token = UUID()
}

struct NotesRequest: Hashable {
    let bibleAbbr: String
    let verseId: String
    let bookId: String
    let chapterId: String
    let title: String
    let verseText: String
}

enum AppRoute: Hashable {
    case notes(NotesRequest)
    case history
    case bookmarksNotes
    case bibles
    case search
    case scriptureOpener(bibleAbbr: String, bibleName: String)
    case scriptureLists
    case scriptureListDetail(id: Int64)
    case settings
    case appearanceSettings
    case readingSettings
    case dataSettings
    case howItWorks
    case help
}

extension Notification.Name {
    static let appDataDidReset = Notification.Name("BibleLibAppDataDidReset")
}

final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var readerTarget: ReaderTarget?

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    func popToRoot() {
        path.removeAll()
    }

    func openReader(_ target: ReaderTarget) {
        readerTarget = target
        path.removeAll()
    }
}
