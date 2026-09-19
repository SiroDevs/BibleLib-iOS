//
//  BibleLibApiService.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

protocol BibleLibApiServiceProtocol {
    func fetchGroups() async throws -> [String]
    func fetchGroupInfo(group: String) async throws -> [BibleInfoDTO]
    func fetchBooks(path: String) async throws -> [BookDTO]
    func fetchChapters(path: String) async throws -> ChaptersResponse
    func fetchVerses(path: String, bookId: String, chapter: String) async throws -> ChapterContentDTO
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

    func fetchGroups() async throws -> [String] {
        try await get([String].self, path: "info.json")
    }

    func fetchGroupInfo(group: String) async throws -> [BibleInfoDTO] {
        try await get([BibleInfoDTO].self, path: "\(group)/info.json")
    }

    func fetchBooks(path: String) async throws -> [BookDTO] {
        try await get([BookDTO].self, path: "\(path)/books.json")
    }

    func fetchChapters(path: String) async throws -> ChaptersResponse {
        try await get(ChaptersResponse.self, path: "\(path)/chapters.json")
    }

    func fetchVerses(path: String, bookId: String, chapter: String) async throws -> ChapterContentDTO {
        try await get(ChapterContentDTO.self, path: "\(path)/verses/\(bookId)/\(chapter).json")
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
