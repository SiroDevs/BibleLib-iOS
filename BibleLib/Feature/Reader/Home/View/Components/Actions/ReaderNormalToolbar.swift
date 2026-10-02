//
//  ReaderNormalToolbar.swift
//  BibleLib
//
//  Created by @sirodevs on 02/10/2026.
//

import SwiftUI

struct ReaderNormalToolbar<MenuContent: View>: ToolbarContent {
    @ObservedObject var viewModel: ReaderViewModel
    let onTapBible: () -> Void
    let onTapBook: () -> Void
    let onSearch: () -> Void
    @ViewBuilder let moreMenu: () -> MenuContent

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Image(.mainIcon)
                .resizable()
                .frame(width: 40, height: 40)
        }

        ToolbarItem(placement: .principal) {
            ReaderTopBar(
                bibleAbbr: viewModel.activeBibleAbbr,
                bibleName: viewModel.activeBible?.name ?? "",
                bookName: viewModel.activeBook?.name ?? "",
                chapterNumber: "\(viewModel.activeChapter?.number ?? "")",
                onTapBible: onTapBible,
                onTapBook: onTapBook
            )
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
            }
            .accessibilityLabel("Search")

            moreMenu()
        }
    }
}
