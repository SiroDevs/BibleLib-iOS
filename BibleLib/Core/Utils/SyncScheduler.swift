//
//  SyncScheduler.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

final class SyncScheduler {
    private static let maxRetries = 3
    private static let backoffSeconds: TimeInterval = 30
    private static let networkPollSeconds: TimeInterval = 3

    private let bibleRepo: BibleRepoProtocol
    private let prefsRepo: PrefsRepo
    private var tasks: [String: (token: UUID, task: Task<Void, Never>)] = [:]
    private let lock = NSLock()

    init(bibleRepo: BibleRepoProtocol, prefsRepo: PrefsRepo) {
        self.bibleRepo = bibleRepo
        self.prefsRepo = prefsRepo
    }

    /// Queues each Bible as its own download. A download that is already in
    /// flight is left alone (Android: `ExistingWorkPolicy.KEEP`).
    func scheduleDownloads(_ abbrs: [String]) {
        for abbr in abbrs {
            schedule(abbr, replacingExisting: false)
        }
    }

    /// Queues one Bible, replacing any download already running for it
    /// (Android: `scheduleSecondaryDownload` / `ExistingWorkPolicy.REPLACE`).
    func scheduleDownload(_ abbr: String) {
        schedule(abbr, replacingExisting: true)
    }

    /// Android's notification "Retry" action.
    func retryDownload(_ abbr: String) {
        scheduleDownload(abbr)
    }

    /// Android's notification "Restart" action: throw away what was downloaded
    /// and start over.
    func restartDownload(_ abbr: String) {
        cancelDownload(abbr)
        bibleRepo.clearBibleContent(abbr: abbr)
        scheduleDownload(abbr)
    }

    func cancelDownload(_ abbr: String) {
        lock.lock()
        let entry = tasks.removeValue(forKey: abbr)
        lock.unlock()
        entry?.task.cancel()
    }

    func cancelAll() {
        lock.lock()
        let running = Array(tasks.values)
        tasks.removeAll()
        lock.unlock()
        running.forEach { $0.task.cancel() }
    }

    /// WorkManager keeps queued work across app restarts; here we re-queue any
    /// chosen Bible that never finished. Bibles already marked failed stay failed
    /// until the user retries them, as on Android.
    func resumeIncompleteDownloads() {
        guard prefsRepo.hasCompletedSelection else { return }

        Task.detached(priority: .utility) { [self] in
            let local = bibleRepo.localBibles()
            let pending = prefsRepo.selectedBibles.filter { abbr in
                guard let bible = local.first(where: { $0.abbreviation == abbr }) else { return false }
                return !bible.isDownloaded && !bible.downloadFailed
            }
            scheduleDownloads(pending)
        }
    }

    // MARK: - Work

    private func schedule(_ abbr: String, replacingExisting: Bool) {
        lock.lock()
        if let existing = tasks[abbr] {
            if !replacingExisting {
                lock.unlock()
                return
            }
            existing.task.cancel()
        }

        let token = UUID()
        let task = Task { [self] in
            await run(abbr)
            finished(abbr, token: token)
        }
        tasks[abbr] = (token, task)
        lock.unlock()
    }

    /// One Bible's worth of SyncWorker.doWork(), including WorkManager's retry loop.
    private func run(_ abbr: String) async {
        var attempt = 0

        while !Task.isCancelled {
            guard NetworkUtils.shared.isNetworkAvailable() else {
                print("SyncScheduler: no network – retrying \(abbr) later")
                await pause(Self.networkPollSeconds)
                continue
            }

            do {
                print("▶ Downloading secondary bible: \(abbr)")
                try await bibleRepo.downloadBible(abbr: abbr, onProgress: { _, _ in })
                prefsRepo.lastSyncedAt = Int(Date().timeIntervalSince1970 * 1000)
                print("✅ Secondary bible \(abbr) downloaded")
                return
            } catch {
                if RetryPolicy.isCancellation(error) { return }

                let failure = RetryPolicy.classify(error)
                print("❌ Failed to download \(abbr): \(failure.localizedDescription)")

                if !failure.isPermanent && attempt < Self.maxRetries {
                    let delay = Self.backoffSeconds * pow(2, Double(attempt))
                    attempt += 1
                    await pause(delay)
                } else {
                    bibleRepo.markDownloadFailed(abbr: abbr)
                    return
                }
            }
        }
    }

    private func pause(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Only clears the entry if it still belongs to the task that just ended,
    /// so a replaced download can't evict its replacement.
    private func finished(_ abbr: String, token: UUID) {
        lock.lock()
        if tasks[abbr]?.token == token {
            tasks.removeValue(forKey: abbr)
        }
        lock.unlock()
    }
}
