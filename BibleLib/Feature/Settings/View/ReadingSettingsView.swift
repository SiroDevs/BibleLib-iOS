//
//  ReadingSettingsView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct ReadingSettingsView: View {
    @StateObject private var viewModel = DiContainer.shared.resolve(SettingsViewModel.self)

    var body: some View {
        let background = ReaderBackgrounds.byId(viewModel.readerBackgroundId)
        let font = ReaderFonts.byId(viewModel.readerFontFamilyId)

        Form {
            Section("Preview") {
                Text("In the beginning God created the heavens and the earth.")
                    .font(font.font(size: CGFloat(viewModel.fontSize)))
                    .foregroundStyle(background.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .listRowBackground(Rectangle().fill(background.background))
            }

            Section("Font size: \(Int(viewModel.fontSize)) pt") {
                HStack(spacing: 12) {
                    Image(systemName: "textformat.size.smaller")
                    Slider(
                        value: Binding(get: { viewModel.fontSize }, set: { viewModel.setFontSize($0) }),
                        in: ReaderFontSize.minimum...ReaderFontSize.maximum,
                        step: 2
                    )
                    Image(systemName: "textformat.size.larger")
                }
                .foregroundStyle(.secondary)
            }

            Section("Font Type") {
                ForEach(ReaderFonts.all) { option in
                    Button {
                        viewModel.setReaderFontFamily(option.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("In the beginning was the Word,")
                                    .font(option.font(size: 17))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            if viewModel.readerFontFamilyId == option.id {
                                Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
    }
}
