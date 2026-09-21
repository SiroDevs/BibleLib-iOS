//
//  ReaderControls.swift
//  BibleLib
//
//  Auto-scroll state, the chapter-edge "pull to continue" rows, the floating
//  buttons and the scripture queue bar.
//

import SwiftUI

// MARK: - Auto scroll

/// Speed and on/off state for auto-scroll (Android: AutoScrollController).
final class AutoScrollController: ObservableObject {
    static let minSpeed = 0.25
    static let maxSpeed = 4.0
    static let step = 0.25

    @Published var isRunning = false
    @Published var speed = 1.0

    func toggle() { isRunning.toggle() }
    func speedUp() { speed = min(speed + Self.step, Self.maxSpeed) }
    func speedDown() { speed = max(speed - Self.step, Self.minSpeed) }

    var speedLabel: String { String(format: "%.2gx", speed) }
}

// MARK: - Chapter edges

/// Shown above the first / below the last verse. If it stays on screen for a
/// moment the reader moves on to the neighbouring chapter (Android: ChapterTransition).
struct ChapterEdgeRow: View {
    enum Edge { case previous, next }

    let edge: Edge
    let label: String
    let isArmed: Bool
    let onTrigger: () -> Void

    @State private var isVisible = false
    @State private var isTransitioning = false

    private struct TaskKey: Equatable {
        let visible: Bool
        let armed: Bool
    }

    var body: some View {
        VStack(spacing: 4) {
            if isTransitioning {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Opening \(label)…")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppColors.primary)
                }
                .transition(.opacity)
            } else {
                Image(systemName: edge == .previous ? "chevron.compact.up" : "chevron.compact.down")
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
        }
        .foregroundStyle(Color(.tertiaryLabel))
        .frame(maxWidth: .infinity, minHeight: 72)
        .animation(.easeInOut(duration: 0.2), value: isTransitioning)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .task(id: TaskKey(visible: isVisible, armed: isArmed)) {
            guard isVisible, isArmed else {
                isTransitioning = false
                return
            }
            isTransitioning = true
            try? await Task.sleep(nanoseconds: 550_000_000)
            if !Task.isCancelled { onTrigger() }
        }
        .accessibilityLabel(edge == .previous ? "Previous chapter, \(label)" : "Next chapter, \(label)")
    }
}

// MARK: - Floating buttons

/// Scripture Opener shortcut plus a jump-to-top button (Android: ReaderFab).
struct ReaderFloatingButtons: View {
    let isAtTop: Bool
    let onScrollToTop: () -> Void
    let onOpenScriptureOpener: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if !isAtTop {
                Button(action: onScrollToTop) {
                    Image(systemName: "chevron.up")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Scroll to top")
                .transition(.scale.combined(with: .opacity))
            }

            Button(action: onOpenScriptureOpener) {
                HStack(spacing: 8) {
                    Image(systemName: "text.magnifyingglass")
                    if isAtTop {
                        Text("Scripture Opener")
                            .font(.subheadline.weight(.semibold))
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, isAtTop ? 16 : 14)
                .frame(height: 48)
                .foregroundStyle(AppColors.onPrimaryContainer)
                .background(AppColors.primaryContainer, in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Scripture Opener")
        }
        .animation(.easeInOut(duration: 0.2), value: isAtTop)
    }
}

/// Slow down / speed up buttons shown while auto-scroll is running.
struct AutoScrollSpeedButtons: View {
    @ObservedObject var controller: AutoScrollController

    var body: some View {
        HStack(spacing: 0) {
            Button(action: controller.speedDown) {
                Image(systemName: "minus")
                    .frame(width: 44, height: 40)
            }
            .accessibilityLabel("Slow down auto scroll")

            Divider().frame(height: 20)

            Button(action: controller.speedUp) {
                Image(systemName: "plus")
                    .frame(width: 44, height: 40)
            }
            .accessibilityLabel("Speed up auto scroll")
        }
        .font(.body.weight(.semibold))
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

// MARK: - Scripture queue

/// Replaces the bottom toolbar while a scripture list is open: one chip per verse,
/// plus options and close (Android: ScriptureQueue).
struct ScriptureQueueBar: View {
    let items: [ScriptureItem]
    let activeItemId: Int64?
    let onSelect: (ScriptureItem) -> Void
    let onOptions: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items) { item in
                            chip(for: item).id(item.id)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 4)
                }
                .onChange(of: activeItemId) { id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
            }

            Button(action: onOptions) {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Options")

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Close scripture list")
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func chip(for item: ScriptureItem) -> some View {
        let isActive = item.id == activeItemId
        return Button { onSelect(item) } label: {
            Text("\(item.bookAbbr.uppercased()) \(item.chapterNumber):\(item.verseNumber)")
                .font(.footnote.weight(isActive ? .bold : .regular))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isActive ? AppColors.onPrimary : .secondary)
                .background(isActive ? AppColors.primary : Color(.secondarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
