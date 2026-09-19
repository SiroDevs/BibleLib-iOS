//
//  SyncScheduler.swift
//  BibleLib
//
//  iOS counterpart of Android's SyncScheduler: every Bible is downloaded as its
//  own independent unit of work, so the primary can finish first and the rest
//  keep going after the Selection screen is gone.
//

import Foundation

final class SyncScheduler {
    private let bibleRepo: BibleRepoProtocol
    private var tasks: [String: (token: UUID, task: Task<Void, Never>)] = [:]
    private let lock = NSLock()

    init(bibleRepo: BibleRepoProtocol) {
        self.bibleRepo = bibleRepo
    }

    /// Queues each Bible as its own download. A download that is already in
    /// flight is left alone (Android: `ExistingWorkPolicy.KEEP`).
    func scheduleDownloads(_ abbrs: [String]) {
        for abbr in abbrs {
            schedule(abbr, replacingExisting: false)
        }
    }

    /// Queues one Bible, replacing any download already running for it
    /// (Android: `ExistingWorkPolicy.REPLACE`).
    func scheduleDownload(_ abbr: String) {
        schedule(abbr, replacingExisting: true)
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
        let task = Task { [bibleRepo] in
            // The repo records failure state itself; nothing more to do here.
            try? await bibleRepo.downloadBible(abbr: abbr, onProgress: { _, _ in })
            self.finished(abbr, token: token)
        }
        tasks[abbr] = (token, task)
        lock.unlock()
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
