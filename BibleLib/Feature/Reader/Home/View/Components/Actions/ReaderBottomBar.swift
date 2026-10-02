//
//  ReaderBottomBar.swift
//  BibleLib
//
//  Created by @sirodevs on 02/10/2026.
//

import SwiftUI

struct ReaderBottomBar: ToolbarContent {
    @ObservedObject var viewModel: ReaderViewModel
    @ObservedObject var autoScroll: AutoScrollController

    let onChapters: () -> Void
    let onOptions: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button { autoScroll.toggle() } label: {
                Image(systemName: autoScroll.isRunning ? "pause.fill" : "play.fill")
            }
            .accessibilityLabel(autoScroll.isRunning ? "Stop auto scroll" : "Start auto scroll")

            Spacer()

            Button { viewModel.navigateChapter(-1) } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.hasPrevChapter)
            .accessibilityLabel("Previous chapter")

            Spacer()

            Button { onChapters() } label: {
                Text("Chapter \(viewModel.activeChapter?.number ?? "")")
                    .font(.subheadline.weight(.semibold))
            }
            .disabled(viewModel.chapters.isEmpty)

            Spacer()

            Button { viewModel.navigateChapter(1) } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.hasNextChapter)
            .accessibilityLabel("Next chapter")

            Spacer()

            Button { onOptions() } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .accessibilityLabel("Options")
        }
    }
}
