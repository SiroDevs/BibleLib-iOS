//
//  ReaderMoreMenu.swift
//  BibleLib
//
//  Created by @sirodevs on 02/10/2026.
//

import SwiftUI

struct ReaderMoreMenu: View {
    let onLists: () -> Void
    let onBookmarks: () -> Void
    let onHistory: () -> Void
    let shareChapterText: String?
    let onSettings: () -> Void

    var body: some View {
        Menu {
            Button(action: onLists) {
                Label("Scripture Lists", systemImage: "list.bullet.rectangle")
            }
            Button(action: onBookmarks) {
                Label("Bookmarks & Notes", systemImage: "bookmark")
            }
            Button(action: onHistory) {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            if let shareChapterText {
                ShareLink(item: shareChapterText) {
                    Label("Share Chapter", systemImage: "square.and.arrow.up")
                }
            }

            Divider()
            Button(action: onSettings) {
                Label("Settings", systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("More")
    }
}
