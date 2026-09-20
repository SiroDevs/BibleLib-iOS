//
//  RetryPolicy.swift
//  BibleLib
//
//  Port of Android's RetryPolicy / DownloadFailure (core/network/.../RetryPolicy.kt):
//
//    5xx / timeout / dropped connection -> retry with exponential backoff
//    429                                -> wait for Retry-After, then retry
//    404                                -> permanent, fail fast
//    401 / 403                          -> permanent, fail fast
//    anything else                      -> retried like a transient failure
//

import Foundation

enum DownloadFailure: Error, LocalizedError {
    case serverError(code: Int)
    case network(underlying: Error?)
    case rateLimited(retryAfter: TimeInterval)
    case notFound
    case unauthorized
    case unknown(underlying: Error?)

    /// True for failures where retrying is pointless (gone / needs auth).
    var isPermanent: Bool {
        switch self {
        case .notFound, .unauthorized: return true
        default: return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .serverError(let code): return "Server error \(code)"
        case .network: return "Network error"
        case .rateLimited: return "Rate limited"
        case .notFound: return "Not found"
        case .unauthorized: return "Unauthorized"
        case .unknown(let underlying): return underlying?.localizedDescription ?? "Unknown error"
        }
    }
}

enum RetryPolicy {
    static let defaultMaxAttempts = 4
    static let defaultInitialDelay: TimeInterval = 1
    static let defaultMaxDelay: TimeInterval = 20
    private static let defaultRateLimitWait: TimeInterval = 5

    static func classify(_ error: Error) -> DownloadFailure {
        if let failure = error as? DownloadFailure { return failure }

        if let api = error as? BibleLibApiError, case .http(let status, let retryAfter, _) = api {
            switch status {
            case 404: return .notFound
            case 401, 403: return .unauthorized
            case 429: return .rateLimited(retryAfter: retryAfter ?? defaultRateLimitWait)
            case 500...599: return .serverError(code: status)
            default: return .unknown(underlying: error)
            }
        }

        if error is URLError { return .network(underlying: error) } // includes timeouts
        return .unknown(underlying: error)
    }

    /// Cancellation is never retried or recorded as a failure.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }

    /// Runs `block`, retrying transient failures with exponential backoff. Throws the
    /// classified `DownloadFailure` once attempts are exhausted or the failure is permanent.
    static func retrying<T>(
        maxAttempts: Int = defaultMaxAttempts,
        initialDelay: TimeInterval = defaultInitialDelay,
        maxDelay: TimeInterval = defaultMaxDelay,
        _ block: () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var backoff = initialDelay

        while true {
            attempt += 1
            do {
                return try await block()
            } catch {
                if isCancellation(error) { throw error }

                let failure = classify(error)
                if failure.isPermanent || attempt >= maxAttempts { throw failure }

                let wait: TimeInterval
                if case .rateLimited(let retryAfter) = failure {
                    wait = retryAfter
                } else {
                    wait = backoff
                    backoff = min(backoff * 2, maxDelay)
                }
                try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
    }
}
