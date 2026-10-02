//
//  BibleSelectorSheet.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct BibleSelectorSheet: View {
    @ObservedObject var viewModel: ReaderViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(viewModel.bibles.filter(\.isDownloaded)) { bible in
                Button {
                    viewModel.setPrimary(bible.abbreviation)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(String(bible.abbreviation.uppercased().prefix(3)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppColors.primary, in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bible.name).foregroundStyle(.primary)
                            Text("\(bible.languageName.uppercased()) · \(bible.description)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if bible.abbreviation == viewModel.activeBibleAbbr {
                            Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Switch Primary Bible")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        BiblesView()
                    } label: {
                        Text("Bibles")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
