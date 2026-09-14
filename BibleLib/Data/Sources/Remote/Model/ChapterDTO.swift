//
//  ChapterDTO.swift
//  BibleLib
//
//  Matches `{abbr}/chapters.json` — mirrors Android's ChapterDto /
//  ChaptersResponse (chapters grouped by book id).
//

import Foundation

struct ChapterDTO: Decodable {
    let id: String
    let bibleId: String
    let bookId: String
    let number: String
    let reference: String
}

typealias ChaptersResponse = [String: [ChapterDTO]]
