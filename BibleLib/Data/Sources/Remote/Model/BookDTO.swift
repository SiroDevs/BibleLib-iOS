//
//  BookDTO.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct BookDTO: Decodable {
    let id: String
    let bibleId: String?
    let abbreviation: String
    let name: String
    let nameLong: String
}
