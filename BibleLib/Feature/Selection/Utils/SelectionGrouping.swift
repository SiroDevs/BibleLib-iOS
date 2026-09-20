//
//  SelectionGrouping.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

let allFilter = "All"

struct FilterOption {
    let name: String
    let count: Int
}

enum GridEntry: Identifiable {
    case header(key: String, title: String, totalCount: Int)
    case countryFilterStrip(key: String, continentKey: String, options: [FilterOption], selected: String)
    case item(key: String, bible: Selectable<BibleInfoDTO>, soloInGroup: Bool)

    /// Same stable keys Android gives its LazyGrid items.
    var id: String {
        switch self {
        case .header(let key, _, _): return "header_\(key)"
        case .countryFilterStrip(let key, _, _, _): return "filter_\(key)"
        case .item(let key, _, _): return "item_\(key)"
        }
    }
}

private let priorityLanguages = ["English", "French"]
private let priorityCountry = "Kenya"

private let regionPriorityOrder = [
    RegionMapper.europe,
    RegionMapper.africa,
    RegionMapper.asia,
    RegionMapper.northAmerica,
    RegionMapper.southAmerica,
    RegionMapper.oceania,
    RegionMapper.antarctica,
    // Unspecified is handled separately so it always sorts last.
]

private func regionPriority(_ region: String) -> Int {
    if region == RegionMapper.unspecified { return Int.max }
    return regionPriorityOrder.firstIndex(of: region) ?? regionPriorityOrder.count
}

func buildGridEntries(
    bibles: [Selectable<BibleInfoDTO>],
    mode: GroupingMode,
    expandedGroups: [String: Bool],
    countryFilters: [String: String] = [:],
    defaultExpanded: Bool = true
) -> [GridEntry] {
    switch mode {
    case .ungrouped:
        let solo = bibles.count <= 1
        return bibles.map {
            .item(key: $0.data.abbreviation, bible: $0, soloInGroup: solo)
        }

    case .languages:
        return buildLanguageEntries(bibles, expandedGroups: expandedGroups, defaultExpanded: defaultExpanded)

    case .countries:
        return buildCountryEntries(
            groups: groupByCountry(bibles),
            keyPrefix: "country",
            expandedGroups: expandedGroups,
            defaultExpanded: defaultExpanded
        )

    case .regions:
        return buildRegionEntries(
            bibles,
            expandedGroups: expandedGroups,
            countryFilters: countryFilters,
            defaultExpanded: defaultExpanded
        )
    }
}

// MARK: - Helpers mirroring Kotlin collection semantics

/// Kotlin's `groupBy` / `LinkedHashMap`: keys keep first-insertion order.
private struct OrderedGroups<Element> {
    private(set) var keys: [String] = []
    private var storage: [String: [Element]] = [:]

    subscript(key: String) -> [Element]? { storage[key] }

    func containsKey(_ key: String) -> Bool { storage[key] != nil }

    mutating func append(_ element: Element, to key: String) {
        if storage[key] == nil {
            keys.append(key)
            storage[key] = []
        }
        storage[key]?.append(element)
    }

    var entries: [(key: String, items: [Element])] {
        keys.map { (key: $0, items: storage[$0] ?? []) }
    }
}

/// Kotlin's `String.compareTo` orders by UTF-16 code unit.
private func kotlinLess(_ a: String, _ b: String) -> Bool {
    a.utf16.lexicographicallyPrecedes(b.utf16)
}

/// Kotlin's `sortedWith` is stable; Swift's `sorted` doesn't promise that, so
/// ties fall back to the original position.
private func stableSorted<T>(_ array: [T], _ isOrderedBefore: (T, T) -> Bool) -> [T] {
    array.enumerated()
        .sorted { lhs, rhs in
            if isOrderedBefore(lhs.element, rhs.element) { return true }
            if isOrderedBefore(rhs.element, lhs.element) { return false }
            return lhs.offset < rhs.offset
        }
        .map { $0.element }
}

// MARK: - Languages

private func languagePriority(_ language: String) -> Int {
    if language.caseInsensitiveCompare("Unspecified") == .orderedSame { return Int.max }
    if let index = priorityLanguages.firstIndex(where: { $0.caseInsensitiveCompare(language) == .orderedSame }) {
        return index
    }
    return priorityLanguages.count
}

private func sortLanguages(
    _ groups: OrderedGroups<Selectable<BibleInfoDTO>>
) -> [(key: String, items: [Selectable<BibleInfoDTO>])] {
    stableSorted(groups.entries) { lhs, rhs in
        let lp = languagePriority(lhs.key), rp = languagePriority(rhs.key)
        if lp != rp { return lp < rp }
        return kotlinLess(lhs.key.lowercased(), rhs.key.lowercased())
    }
}

private func buildLanguageEntries(
    _ bibles: [Selectable<BibleInfoDTO>],
    expandedGroups: [String: Bool],
    defaultExpanded: Bool
) -> [GridEntry] {
    var groups = OrderedGroups<Selectable<BibleInfoDTO>>()
    for bible in bibles {
        let name = bible.data.language.name
        groups.append(bible, to: name.isEmpty || name.allSatisfy(\.isWhitespace) ? "Unspecified" : name)
    }

    var result: [GridEntry] = []
    for (language, items) in sortLanguages(groups) {
        let key = "language:\(language)"
        let isExpanded = expandedGroups[key] ?? defaultExpanded

        result.append(.header(key: key, title: language, totalCount: items.count))
        if isExpanded {
            result.append(contentsOf: items.map {
                .item(key: "\(key):\($0.data.abbreviation)", bible: $0, soloInGroup: items.count == 1)
            })
        }
    }
    return result
}

// MARK: - Countries

private func groupByCountry(
    _ bibles: [Selectable<BibleInfoDTO>]
) -> OrderedGroups<Selectable<BibleInfoDTO>> {
    var byCountry = OrderedGroups<Selectable<BibleInfoDTO>>()
    for selectable in bibles {
        for country in selectable.data.countryRefs() {
            byCountry.append(selectable, to: country.name)
        }
    }
    return byCountry
}

private func countryPriority(_ country: String, _ items: [Selectable<BibleInfoDTO>]) -> Int {
    if country.caseInsensitiveCompare(unspecifiedCountryName) == .orderedSame { return Int.max }
    if items.contains(where: { $0.data.language.name.caseInsensitiveCompare(priorityLanguages[0]) == .orderedSame }) { return 0 }
    if items.contains(where: { $0.data.language.name.caseInsensitiveCompare(priorityLanguages[1]) == .orderedSame }) { return 1 }
    if country.caseInsensitiveCompare(priorityCountry) == .orderedSame { return 2 }
    return 3
}

private func sortCountries(
    _ groups: OrderedGroups<Selectable<BibleInfoDTO>>
) -> [(key: String, items: [Selectable<BibleInfoDTO>])] {
    stableSorted(groups.entries) { lhs, rhs in
        let lp = countryPriority(lhs.key, lhs.items), rp = countryPriority(rhs.key, rhs.items)
        if lp != rp { return lp < rp }
        return kotlinLess(lhs.key.lowercased(), rhs.key.lowercased())
    }
}

private func buildCountryEntries(
    groups: OrderedGroups<Selectable<BibleInfoDTO>>,
    keyPrefix: String,
    expandedGroups: [String: Bool],
    defaultExpanded: Bool
) -> [GridEntry] {
    var result: [GridEntry] = []
    for (country, items) in sortCountries(groups) {
        let key = "\(keyPrefix):\(country)"
        let isExpanded = expandedGroups[key] ?? defaultExpanded

        result.append(.header(key: key, title: country, totalCount: items.count))
        if isExpanded {
            result.append(contentsOf: items.map {
                .item(key: "\(key):\($0.data.abbreviation)", bible: $0, soloInGroup: items.count == 1)
            })
        }
    }
    return result
}

// MARK: - Regions

private final class RegionBucket {
    var items: [Selectable<BibleInfoDTO>] = []
    private var seenAbbreviations = Set<String>()
    var byCountry = OrderedGroups<Selectable<BibleInfoDTO>>()

    func addDistinct(_ bible: Selectable<BibleInfoDTO>) {
        if seenAbbreviations.insert(bible.data.abbreviation).inserted {
            items.append(bible)
        }
    }
}

private func buildRegionEntries(
    _ bibles: [Selectable<BibleInfoDTO>],
    expandedGroups: [String: Bool],
    countryFilters: [String: String],
    defaultExpanded: Bool
) -> [GridEntry] {
    var regionKeys: [String] = []
    var byRegion: [String: RegionBucket] = [:]

    for selectable in bibles {
        for country in selectable.data.countryRefs() {
            let continent = RegionMapper.continent(for: country.id)
            let bucket: RegionBucket
            if let existing = byRegion[continent] {
                bucket = existing
            } else {
                bucket = RegionBucket()
                byRegion[continent] = bucket
                regionKeys.append(continent)
            }
            bucket.addDistinct(selectable)
            bucket.byCountry.append(selectable, to: country.name)
        }
    }

    let orderedRegions = stableSorted(regionKeys) { lhs, rhs in
        let lp = regionPriority(lhs), rp = regionPriority(rhs)
        if lp != rp { return lp < rp }
        return kotlinLess(lhs.lowercased(), rhs.lowercased())
    }

    var result: [GridEntry] = []
    for continent in orderedRegions {
        guard let bucket = byRegion[continent] else { continue }
        let continentKey = "continent:\(continent)"
        let continentExpanded = expandedGroups[continentKey] ?? defaultExpanded

        result.append(.header(key: continentKey, title: continent, totalCount: bucket.items.count))
        guard continentExpanded else { continue }

        let orderedCountries = sortCountries(bucket.byCountry)

        var options = [FilterOption(name: allFilter, count: bucket.items.count)]
        for (country, items) in orderedCountries {
            options.append(FilterOption(name: country, count: items.count))
        }

        let requested = countryFilters[continentKey]
        let selected: String
        if let requested, requested == allFilter || bucket.byCountry.containsKey(requested) {
            selected = requested
        } else {
            selected = allFilter
        }

        result.append(
            .countryFilterStrip(
                key: "\(continentKey):filter",
                continentKey: continentKey,
                options: options,
                selected: selected
            )
        )

        let filteredItems = selected == allFilter ? bucket.items : (bucket.byCountry[selected] ?? [])
        let solo = filteredItems.count == 1

        result.append(contentsOf: filteredItems.map {
            .item(key: "\(continentKey):\($0.data.abbreviation)", bible: $0, soloInGroup: solo)
        })
    }
    return result
}
