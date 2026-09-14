//
//  BookDTO.swift
//  BibleLib
//
//  Matches `{abbr}/books.json` — mirrors Android's BookDto.
//

import Foundation

struct BookDTO: Decodable {
    let id: String
    let bibleId: String
    let abbreviation: String
    let name: String
    let nameLong: String
}
