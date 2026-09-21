//
//  SelectionRows.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct SelectionSection: Identifiable {
    struct Header {
        let key: String
        let title: String
        let total: Int
    }

    struct CountryFilter {
        let continentKey: String
        let options: [FilterOption]
        let selected: String
    }

    let id: String
    var header: Header?
    var filter: CountryFilter?
    var items: [Selectable<BibleInfoDTO>] = []

    /// Groups the flat grid entries into one List section per header.
    static func make(from entries: [GridEntry]) -> [SelectionSection] {
        var sections: [SelectionSection] = []

        for entry in entries {
            switch entry {
            case .header(let key, let title, let total):
                sections.append(SelectionSection(id: key, header: Header(key: key, title: title, total: total)))
            case .countryFilterStrip(_, let continentKey, let options, let selected):
                guard !sections.isEmpty else { continue }
                sections[sections.count - 1].filter = CountryFilter(continentKey: continentKey, options: options, selected: selected)
            case .item(_, let bible, _):
                if sections.isEmpty { sections.append(SelectionSection(id: "all")) }
                sections[sections.count - 1].items.append(bible)
            }
        }
        return sections
    }
}

struct BibleRow: View {
    let bible: BibleInfoDTO
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(String(bible.abbreviation.uppercased().prefix(3)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? AppColors.primary : Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(bible.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(bible.description.isEmpty ? bible.language.name : bible.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(bible.language.name) Bible".uppercased())
                        .font(.caption2)
                        .foregroundStyle(AppColors.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primary)
                        .imageScale(.large)
                }
            }
        }
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct BibleRowPlaceholder: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10).frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text("King James Version").font(.body)
                Text("The classic English translation").font(.caption)
            }
        }
        .redacted(reason: .placeholder)
    }
}

struct SavingProgressView: View {
    let progress: Double
    let step: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress) {
                Text("Downloading your primary Bible").font(.headline)
            } currentValueLabel: {
                Text(progress, format: .percent.precision(.fractionLength(0)))
            }
            Text(step)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("The rest of your Bibles will download in the background once your primary Bible is downloaded.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxHeight: .infinity)
        .animation(.easeOut(duration: 0.3), value: progress)
    }
}

struct DownloadFailedView: View {
    let message: String
    let progress: Double
    let onRestart: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Download Failed").font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            ProgressView(value: progress)
            Text("\(Int(progress * 100))% done before it stopped")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Restart", action: onRestart)
                    .buttonStyle(.bordered)
                Button("Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .padding(32)
        .frame(maxHeight: .infinity)
    }
}
