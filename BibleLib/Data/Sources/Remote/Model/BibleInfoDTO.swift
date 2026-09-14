//
//  BibleInfoDTO.swift
//  BibleLib
//
//  Matches `info.json` — mirrors Android's BibleInfoDto exactly.
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
