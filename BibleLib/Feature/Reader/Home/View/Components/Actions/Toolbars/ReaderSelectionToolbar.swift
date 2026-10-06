//
//  ReaderSelectionToolbar.swift
//  BibleLib
//
//  Created by @sirodevs on 02/10/2026.
//

import SwiftUI

struct ReaderSelectionToolbar: ToolbarContent {
    @ObservedObject var viewModel: ReaderViewModel
    let onCancel: () -> Void
    let onHighlight: () -> Void
    let onAddNote: () -> Void
    let onCopy: () -> Void
    let shareText: String?

    private var selection: VerseSelectionModel { viewModel.selection }

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: onCancel) {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Cancel selection")
        }

        ToolbarItem(placement: .principal) {
            Text("\(selection.selectedIds.count) selected").font(.headline)
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: onHighlight) {
                Image(systemName: "highlighter")
            }
            .accessibilityLabel("Highlight and bookmark")

            Button(action: onAddNote) {
                Image(systemName: "note.text.badge.plus")
            }
            .disabled(selection.selectedIds.count != 1)
            .accessibilityLabel("Add note")

            if let shareText {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Copy")

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}
