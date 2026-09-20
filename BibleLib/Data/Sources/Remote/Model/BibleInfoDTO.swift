//
//  BibleInfoDTO.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct BibleInfoDTO: Decodable {
    let name: String
    let description: String
    let abbreviation: String
    let tagline: String
    let language: BibleLangDTO
    let countries: [BibleCountryDTO]
    let info: String
    let path: String

    enum CodingKeys: String, CodingKey {
        case name, description, abbreviation, tagline, language, countries, info, path
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decode(String.self, forKey: .description)
        abbreviation = try c.decode(String.self, forKey: .abbreviation)
        tagline = try c.decode(String.self, forKey: .tagline)
        language = try c.decode(BibleLangDTO.self, forKey: .language)
        countries = try c.decode([BibleCountryDTO].self, forKey: .countries)
        info = try c.decode(String.self, forKey: .info)
        path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
    }

    func primaryCountryName() -> String {
        let first = countries.first?.name ?? ""
        return first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Other" : first
    }
}

struct BibleLangDTO: Decodable {
    let id: String
    let name: String
    let script: String
    let scriptDirection: String
}

struct BibleCountryDTO: Decodable {
    let id: String
    let name: String
}
