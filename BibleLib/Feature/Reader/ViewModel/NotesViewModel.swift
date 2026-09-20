//
//  NotesViewModel.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import Foundation

final class NotesViewModel: ObservableObject {
    @Published var noteText = ""
    @Published private(set) var isSaved = true
    @Published private(set) var request: NotesRequest?

    private let annotationRepo: AnnotationRepo
    private var savedText = ""

    init(annotationRepo: AnnotationRepo) {
        self.annotationRepo = annotationRepo
    }

    func initialize(_ request: NotesRequest) {
        guard self.request != request else { return }
        self.request = request
        savedText = annotationRepo.note(abbr: request.bibleAbbr, verseId: request.verseId)?.noteText ?? ""
        noteText = savedText
        isSaved = true
    }

    func noteTextChanged() {
        isSaved = (noteText == savedText)
    }

    func save() {
        guard let request else { return }
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            annotationRepo.deleteNote(abbr: request.bibleAbbr, verseId: request.verseId)
        } else {
            annotationRepo.saveNote(
                Note(
                    verseId: request.verseId,
                    bibleAbbr: request.bibleAbbr,
                    bookId: request.bookId,
                    chapterId: request.chapterId,
                    title: request.title,
                    verseText: request.verseText,
                    noteText: noteText
                )
            )
        }
        savedText = noteText
        isSaved = true
    }
}
