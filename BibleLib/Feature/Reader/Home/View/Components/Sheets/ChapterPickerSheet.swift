//
//  ChapterPickerSheet.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct ChapterPickerSheet: View {
    @ObservedObject var viewModel: ReaderViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 8)], spacing: 8) {
                    ForEach(viewModel.chapters) { chapter in
                        let isActive = chapter.id == viewModel.activeChapter?.id
                        Button {
                            viewModel.select(chapter)
                            dismiss()
                        } label: {
                            Text(chapter.number)
                                .font(.body.weight(isActive ? .bold : .regular))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(isActive ? AppColors.onPrimaryContainer : Color.primary)
                                .background(
                                    isActive ? AppColors.primaryContainer : Color(.secondarySystemFill),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Jump to a Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
