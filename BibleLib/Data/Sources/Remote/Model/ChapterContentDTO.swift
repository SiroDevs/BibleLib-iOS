//
//  ChapterContentDTO.swift
//  BibleLib
//
//  Matches `{abbr}/verses/{bookId}/{chapter}.json` — mirrors Android's
//  ChapterContentDto / ContentItemDto exactly, including the two quirks
//  the real payload requires handling:
//
//  1. `content` can contain literal JSON `null` entries — decoded as
//     `[ContentItemDTO?]` and skipped rather than failing the chapter.
//  2. `attrs` values are sometimes numbers/booleans instead of strings —
//     LenientStringMap below mirrors Android's LenientAttrsAdapter by
//     coercing any JSON scalar to its string form.
//

import Foundation

struct ChapterContentDTO: Decodable {
    let id: String
    let bibleId: String
    let number: String
    let bookId: String
    let reference: String
    let verseCount: Int
    let content: [ContentItemDTO?]
}

/// One node in the chapter's structured content tree: verse markers, text
/// runs, headings, and nested items are all represented the same way.
struct ContentItemDTO: Decodable {
    let name: String?
    let type: String
    let text: String?
    let attrs: [String: String]?
    let items: [ContentItemDTO?]?

    enum CodingKeys: String, CodingKey { case name, type, text, attrs, items }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        text = try container.decodeIfPresent(String.self, forKey: .text)
        items = try container.decodeIfPresent([ContentItemDTO?].self, forKey: .items)
        attrs = try container.decodeIfPresent(LenientStringMap.self, forKey: .attrs)?.value
    }
}

struct LenientStringMap: Decodable {
    let value: [String: String]

    struct AnyKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        var result: [String: String] = [:]
        for key in container.allKeys {
            if let s = try? container.decode(String.self, forKey: key) {
                result[key.stringValue] = s
            } else if let i = try? container.decode(Int.self, forKey: key) {
                result[key.stringValue] = String(i)
            } else if let d = try? container.decode(Double.self, forKey: key) {
                result[key.stringValue] = String(d)
            } else if let b = try? container.decode(Bool.self, forKey: key) {
                result[key.stringValue] = String(b)
            }
            // null / array / object values are skipped, matching Android.
        }
        value = result
    }
}
