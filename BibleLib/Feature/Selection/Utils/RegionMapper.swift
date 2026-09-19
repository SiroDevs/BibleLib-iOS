//
//  RegionMapper.swift
//  BibleLib
//
//  Port of Android's RegionMapper (feature/selection/.../utils/RegionMapper.kt).
//  Maps an ISO country code to the continent used for "Regions" grouping.
//

import Foundation

enum RegionMapper {
    static let asia = "Asia"
    static let africa = "Africa"
    static let antarctica = "Antarctica"
    static let europe = "Europe"
    static let northAmerica = "North America"
    static let southAmerica = "South America"
    static let oceania = "Oceania"
    static let unspecified = "Unspecified"

    static let unspecifiedCountryId = "ZZ"

    static func continent(for countryId: String) -> String {
        if countryId.caseInsensitiveCompare(unspecifiedCountryId) == .orderedSame { return unspecified }
        return codeToRegion[countryId.uppercased()] ?? unspecified
    }

    private static let codeToRegion: [String: String] = {
        var map: [String: String] = [:]

        func register(_ continent: String, _ codes: [String]) {
            for code in codes { map[code] = continent }
        }

        register(europe, [
            "AL", "AD", "AT", "BY", "BE", "BA", "BG", "HR", "CZ", "DK", "EE", "FO", "FI", "FR",
            "DE", "GI", "GR", "GG", "VA", "HU", "IS", "IE", "IM", "IT", "JE", "XK", "LV", "LI",
            "LT", "LU", "MT", "MD", "MC", "ME", "NL", "MK", "NO", "PL", "PT", "RO", "RU", "SM",
            "RS", "SK", "SI", "ES", "SJ", "SE", "CH", "UA", "GB", "AX",
        ])
        register(africa, [
            "DZ", "AO", "BJ", "BW", "BF", "BI", "CV", "CM", "CF", "TD", "KM", "CG", "CD", "CI",
            "DJ", "EG", "GQ", "ER", "SZ", "ET", "GA", "GM", "GH", "GN", "GW", "KE", "LS", "LR",
            "LY", "MG", "MW", "ML", "MR", "MU", "YT", "MA", "MZ", "NA", "NE", "NG", "RE", "RW",
            "SH", "ST", "SN", "SC", "SL", "SO", "ZA", "SS", "SD", "TZ", "TG", "TN", "UG", "EH",
            "ZM", "ZW", "SA",
        ])
        register(asia, [
            "AF", "AM", "AZ", "BH", "BD", "BT", "BN", "KH", "CN", "CY", "GE", "HK", "IN", "ID",
            "IR", "IQ", "IL", "JP", "JO", "KZ", "KP", "KR", "KW", "KG", "LA", "LB", "MO", "MY",
            "MV", "MN", "MM", "NP", "OM", "PK", "PS", "PH", "QA", "SG", "LK", "SY", "TW", "TJ",
            "TH", "TL", "TR", "TM", "AE", "UZ", "VN", "YE",
        ])
        register(northAmerica, [
            "AI", "AG", "AW", "BS", "BB", "BZ", "BM", "VG", "CA", "KY", "CR", "CU", "CW", "DM",
            "DO", "SV", "GL", "GD", "GP", "GT", "HT", "HN", "JM", "MQ", "MX", "MS", "NI", "PA",
            "PR", "BL", "KN", "LC", "MF", "PM", "VC", "SX", "TT", "TC", "US", "VI",
        ])
        register(southAmerica, [
            "AR", "BO", "BR", "CL", "CO", "EC", "FK", "GF", "GY", "PY", "PE", "SR", "UY", "VE",
        ])
        register(oceania, [
            "AS", "AU", "CK", "FJ", "PF", "GU", "KI", "MH", "FM", "NR", "NC", "NZ", "NU", "NF",
            "MP", "PW", "PG", "PN", "WS", "SB", "TK", "TO", "TV", "VU", "WF",
        ])
        register(antarctica, [
            "AQ", "BV", "TF", "GS", "HM",
        ])

        return map
    }()
}
