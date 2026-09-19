//
//  GroupingExtensions.swift
//  BibleLib
//
//  Port of Android's GroupingExtensions.kt.
//

import Foundation

struct CountryRef {
    let id: String
    let name: String
}

/// Deliberately spelled like Android's constant so both apps show the same header.
let unspecifiedCountryName = "Unspecific"

extension BibleInfoDTO {
    func countryRefs() -> [CountryRef] {
        let refs = countries.map { CountryRef(id: $0.id, name: $0.name) }
        if refs.isEmpty {
            return [CountryRef(id: RegionMapper.unspecifiedCountryId, name: unspecifiedCountryName)]
        }
        return refs
    }
}

extension CountryRef {
    func isUnspecified() -> Bool {
        id.caseInsensitiveCompare(RegionMapper.unspecifiedCountryId) == .orderedSame ||
            name.caseInsensitiveCompare(unspecifiedCountryName) == .orderedSame
    }
}
