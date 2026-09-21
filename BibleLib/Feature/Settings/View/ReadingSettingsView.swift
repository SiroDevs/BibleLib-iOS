//
//  ReadingSettingsView.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct ReadingSettingsView: View {
    @AppStorage(PrefConstants.fontSize) private var fontSize = ReaderFontSize.standard
    @AppStorage(PrefConstants.readerFontFamily) private var fontFamily = "default"
    @AppStorage(PrefConstants.readerBackground) private var backgroundId = "default"

    var body: some View {
        let page = ReaderBackgrounds.byId(backgroundId)

        Form {
            Section("Preview") {
                Text("In the beginning God created the heavens and the earth.")
                    .font(ReaderFonts.byId(fontFamily).font(size: CGFloat(fontSize)))
                    .foregroundStyle(page.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .listRowBackground(Rectangle().fill(page.background))
            }

            Section("Font size: \(Int(fontSize)) pt") {
                HStack(spacing: 12) {
                    Image(systemName: "textformat.size.smaller")
                    Slider(value: $fontSize, in: ReaderFontSize.minimum...ReaderFontSize.maximum, step: 2)
                    Image(systemName: "textformat.size.larger")
                }
                .foregroundStyle(.secondary)
            }

            Section("Font") {
                Picker("Font", selection: $fontFamily) {
                    ForEach(ReaderFonts.all) { option in
                        Text(option.displayName)
                            .font(option.font(size: 17))
                            .tag(option.id)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
    }
}
