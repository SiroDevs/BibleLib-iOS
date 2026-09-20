//
//  GroupingExtensions.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct CountryRef {
    let id: String
    let name: String
}

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
