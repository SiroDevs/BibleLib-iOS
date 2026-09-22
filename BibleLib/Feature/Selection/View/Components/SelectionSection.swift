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
    var isSolo = false
    var usesGrid: Bool { !isSolo && !items.isEmpty }

    static func make(from entries: [GridEntry]) -> [SelectionSection] {
        var sections: [SelectionSection] = []

        for entry in entries {
            switch entry {
            case .header(let key, let title, let total):
                sections.append(SelectionSection(id: key, header: Header(key: key, title: title, total: total)))
                
            case .countryFilterStrip(_, let continentKey, let options, let selected):
                guard !sections.isEmpty else { continue }
                sections[sections.count - 1].filter = CountryFilter(continentKey: continentKey, options: options, selected: selected)
                
            case .item(_, let bible, let soloInGroup):
                if sections.isEmpty { sections.append(SelectionSection(id: "all")) }
                sections[sections.count - 1].items.append(bible)
                sections[sections.count - 1].isSolo = soloInGroup
            }
        }
        return sections
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var fillsWidth = false
    let id: AnyHashable
    let namespace: Namespace.ID
    let onTap: () -> Void
 
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { onTap() }
        } label: {
            styled(text)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
 
    private var text: some View {
        Text(label)
            .font(.footnote.weight(isSelected ? .semibold : .regular))
            .lineLimit(1)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant)
    }
 
    @ViewBuilder
    private func styled(_ content: some View) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    isSelected ? .regular.tint(AppColors.primary).interactive() : .regular.interactive()
                )
                .glassEffectID(id, in: namespace)
        } else {
            content.background(isSelected ? AppColors.primary : AppColors.surfaceVariant, in: Capsule())
        }
    }
}


struct CountryFilterStrip: View {
    let filter: SelectionSection.CountryFilter
    let onSelect: (String) -> Void
    @Namespace private var glassNamespace
 
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                chipRow
                    .padding(.vertical, 2)
            }
            .onAppear {
                withAnimation(nil) { proxy.scrollTo(filter.selected, anchor: .leading) }
            }
            .onChange(of: filter.selected) { selected in
                withAnimation { proxy.scrollTo(selected, anchor: .center) }
            }
        }
    }
 
    @ViewBuilder
    private var chipRow: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 8) { chips }
        } else {
            chips
        }
    }
 
    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(filter.options, id: \.name) { option in
                FilterChip(
                    label: "\(option.name) (\(option.count))",
                    isSelected: option.name == filter.selected,
                    id: option.name,
                    namespace: glassNamespace
                ) {
                    onSelect(option.name)
                }
                .id(option.name)
            }
        }
    }
}
