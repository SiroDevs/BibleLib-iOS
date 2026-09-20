//
//  ChapterDTO.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct ChapterDTO: Decodable {
    let id: String
    let bibleId: String?
    let bookId: String
    let number: String
    let reference: String
}
 
typealias ChaptersResponse = [String: [ChapterDTO]]
