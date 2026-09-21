//
//  ReaderShareText.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import Foundation

enum ReaderShareText {
    static func verses(_ ids: Set<String>, in context: ChapterContext, bible: Bible?) -> String? {
        let chosen = context.verses.filter { ids.contains($0.verseId) }.sorted { $0.number < $1.number }
        guard !chosen.isEmpty else { return nil }
        let reference = "\(context.book.name) \(context.chapter.number):\(range(chosen.map(\.number)))"
        return format(reference: reference, verses: chosen, bible: bible)
    }

    static func chapter(_ context: ChapterContext, bible: Bible?) -> String? {
        guard !context.verses.isEmpty else { return nil }
        let reference = "\(context.book.name) \(context.chapter.number)"
        return format(reference: reference, verses: context.verses.sorted { $0.number < $1.number }, bible: bible)
    }

    static func range(_ numbers: [Int]) -> String {
        var parts: [String] = []
        var start: Int?
        var previous = 0

        func close() {
            guard let first = start else { return }
            parts.append(first == previous ? "\(first)" : "\(first)-\(previous)")
        }

        for number in numbers.sorted() {
            if start != nil, number == previous + 1 {
                previous = number
            } else {
                close()
                start = number
                previous = number
            }
        }
        close()
        return parts.joined(separator: ", ")
    }

    private static func format(reference: String, verses: [VerseDisplay], bible: Bible?) -> String {
        let body = verses.map { "\($0.number) \($0.text)" }.joined(separator: "\n")
        let footnote = bible.map { "\($0.name) (\($0.languageName))" } ?? ""
        return "\(reference)\n\n\(body)\n\n— \(footnote)"
    }
}
