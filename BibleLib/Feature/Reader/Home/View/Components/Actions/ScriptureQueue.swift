//
//  ScriptureQueue.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct ScriptureQueue: View {
    @ObservedObject var viewModel: ReaderViewModel
    let onOptions: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.queueItems) { item in
                            chip(for: item).id(item.id)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 4)
                }
                .onChange(of: viewModel.queueActiveItemId) { id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
            }

            Button(action: onOptions) {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Options")

            Button { viewModel.dismissQueue() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Close scripture list")
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func chip(for item: ScriptureItem) -> some View {
        let isActive = item.id == viewModel.queueActiveItemId
        return Button { viewModel.jump(to: item) } label: {
            Text("\(item.bookAbbr.uppercased()) \(item.chapterNumber):\(item.verseNumber)")
                .font(.footnote.weight(isActive ? .bold : .regular))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isActive ? AppColors.onPrimary : .secondary)
                .background(isActive ? AppColors.primary : Color(.secondarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
