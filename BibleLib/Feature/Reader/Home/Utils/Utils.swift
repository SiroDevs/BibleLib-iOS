//
//  Utils.swift
//  BibleLib
//
//  Created by @sirodevs on 02/10/2026.
//

enum ReaderSheet: String, Identifiable {
    case books, chapters, quickSettings, bibles

    var id: String { rawValue }
}

enum ReaderRoute: Hashable {
    case bibles, bookmarks, history, search, lists, opener
}
