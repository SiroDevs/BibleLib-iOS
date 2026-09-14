//
//  BibleLibApiService.swift
//  BibleLib
//
//  Mirrors Android's BibleLibService (Retrofit interface): four flat,
//  pre-generated JSON endpoints, no query params, no pagination.
//

import Foundation

protocol BibleLibApiServiceProtocol {
    func fetchBiblesInfo() async throws -> [BibleInfoDTO]
    func fetchBooks(abbr: String) async throws -> [BookDTO]
    func fetchChapters(abbr: String) async throws -> ChaptersResponse
    func fetchVerses(abbr: String, bookId: String, chapter: String) async throws -> ChapterContentDTO
}

enum BibleLibApiError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let path): return "Failed to fetch \(path)"
        }
    }
}

final class BibleLibApiService: BibleLibApiServiceProtocol {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = URL(string: AppConstants.bibleLibBaseURL)!) {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchBiblesInfo() async throws -> [BibleInfoDTO] {
        try await get([BibleInfoDTO].self, path: "info.json")
    }

    func fetchBooks(abbr: String) async throws -> [BookDTO] {
        try await get([BookDTO].self, path: "\(abbr)/books.json")
    }

    func fetchChapters(abbr: String) async throws -> ChaptersResponse {
        try await get(ChaptersResponse.self, path: "\(abbr)/chapters.json")
    }

    func fetchVerses(abbr: String, bookId: String, chapter: String) async throws -> ChapterContentDTO {
        try await get(ChapterContentDTO.self, path: "\(abbr)/verses/\(bookId)/\(chapter).json")
    }

    private func get<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BibleLibApiError.requestFailed(path)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
