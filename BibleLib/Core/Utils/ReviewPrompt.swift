//
//  ReviewPrompt.swift
//
//  Reusable, self-contained app review prompt. Copy this single file into any
//  SwiftUI app (iOS 16+).
//
//  Setup:
//    1. App.init():            ReviewPromptManager.shared.configure()   // starts the first-launch clock
//    2. On your target screen: .reviewPrompt()                          // that's it
//
//  Flow: after `initialDelay` since first launch -> "Are you enjoying the app?" (Yes / No)
//        -> "Review Now / Later". Review Now = StoreKit review request, never asked again.
//        Later = wait `reminderDelay`, then the flow can appear again.
//

import SwiftUI
import StoreKit

// MARK: - Configuration

struct ReviewPromptConfig {
    /// Time since first launch before the prompt may appear.
    var initialDelay: TimeInterval = 48 * 60 * 60
    /// Time to wait after the user taps "Later".
    var reminderDelay: TimeInterval = 48 * 60 * 60
    /// Pause after the screen appears, so the dialog never pops up instantly.
    var presentationDelay: TimeInterval = 2
    /// Change this when copying to another app if you want unique keys.
    var keyPrefix = "reviewPrompt"
}

// MARK: - Manager

@MainActor
final class ReviewPromptManager: ObservableObject {
    static let shared = ReviewPromptManager()

    enum Step { case enjoying, review }

    /// Which dialog is currently showing (nil = none).
    @Published fileprivate(set) var step: Step?

    private(set) var config: ReviewPromptConfig
    private let defaults: UserDefaults

    /// In-memory only: guarantees the flow starts at most once per app session,
    /// no matter how many times the screen appears or re-renders.
    private var startedThisSession = false

    /// UserDefaults keys (all derived from `config.keyPrefix`).
    ///  - firstLaunchDate : Double  (timeIntervalSince1970) written once, on first launch
    ///  - lastDeferredDate: Double  (timeIntervalSince1970) written when user taps "Later"
    ///  - isHandled       : Bool    true after "Review Now"; the prompt never shows again
    private enum Key: String {
        case firstLaunchDate, lastDeferredDate, isHandled
    }

    private func key(_ key: Key) -> String { "\(config.keyPrefix).\(key.rawValue)" }

    init(defaults: UserDefaults = .standard, config: ReviewPromptConfig = ReviewPromptConfig()) {
        self.defaults = defaults
        self.config = config
        recordFirstLaunchIfNeeded()
    }

    /// Call from `App.init()`. Optionally pass custom delays / key prefix.
    func configure(_ config: ReviewPromptConfig = ReviewPromptConfig()) {
        self.config = config
        recordFirstLaunchIfNeeded()
    }

    // MARK: Persistence

    private func recordFirstLaunchIfNeeded() {
        guard defaults.object(forKey: key(.firstLaunchDate)) == nil else { return }
        defaults.set(Date().timeIntervalSince1970, forKey: key(.firstLaunchDate))
    }

    private var isHandled: Bool { defaults.bool(forKey: key(.isHandled)) }

    private func date(for key: Key) -> Date? {
        guard let seconds = defaults.object(forKey: self.key(key)) as? Double else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    // MARK: Eligibility

    private func isEligible(now: Date = Date()) -> Bool {
        guard !isHandled, let firstLaunch = date(for: .firstLaunchDate) else { return false }
        guard now.timeIntervalSince(firstLaunch) >= config.initialDelay else { return false }
        if let deferred = date(for: .lastDeferredDate),
           now.timeIntervalSince(deferred) < config.reminderDelay {
            return false
        }
        return true
    }

    /// Safe to call as often as you like; only the first eligible call per session starts the flow.
    func startIfEligible() {
        guard step == nil, !startedThisSession, isEligible() else { return }
        startedThisSession = true
        step = .enjoying
    }

    // MARK: User actions

    /// "Yes" or "No" – both lead to the review dialog.
    fileprivate func answerEnjoying() {
        step = nil
        Task { @MainActor in
            // Let the first alert finish dismissing before presenting the next one.
            try? await Task.sleep(nanoseconds: 500_000_000)
            step = .review
        }
    }

    fileprivate func reviewNow() {
        defaults.set(true, forKey: key(.isHandled))
        step = nil
    }

    fileprivate func later() {
        defaults.set(Date().timeIntervalSince1970, forKey: key(.lastDeferredDate))
        step = nil
    }

    #if DEBUG
    /// For testing: clears all stored state and allows the flow to start again.
    func debugReset() {
        [Key.firstLaunchDate, .lastDeferredDate, .isHandled].forEach { defaults.removeObject(forKey: key($0)) }
        startedThisSession = false
        step = nil
        recordFirstLaunchIfNeeded()
    }
    #endif
}

// MARK: - SwiftUI integration

private struct ReviewPromptModifier: ViewModifier {
    @ObservedObject private var manager = ReviewPromptManager.shared
    @Environment(\.requestReview) private var requestReview

    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            // Runs once per appearance / once per isEnabled change – not on every re-render.
            .task(id: isEnabled) {
                guard isEnabled else { return }
                try? await Task.sleep(nanoseconds: UInt64(manager.config.presentationDelay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                manager.startIfEligible()
            }
            .alert(
                manager.step == .review ? "Would you leave a review?" : "Are you enjoying the app?",
                isPresented: Binding(get: { manager.step != nil }, set: { _ in }),
                presenting: manager.step
            ) { step in
                switch step {
                case .enjoying:
                    Button("Yes") { manager.answerEnjoying() }
                    Button("No") { manager.answerEnjoying() }
                case .review:
                    Button("Review Now") {
                        manager.reviewNow()
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            // iOS decides whether to show the sheet (rate limits etc.); no result to handle.
                            requestReview()
                        }
                    }
                    Button("Later", role: .cancel) { manager.later() }
                }
            } message: { step in
                if step == .review {
                    Text("A quick rating helps other people find the app.")
                }
            }
    }
}

extension View {
    /// Attach to the screen that should host the review prompt.
    /// - Parameter isEnabled: pass `false` while sheets, pushed screens or selections are active.
    func reviewPrompt(isEnabled: Bool = true) -> some View {
        modifier(ReviewPromptModifier(isEnabled: isEnabled))
    }
}
