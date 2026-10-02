//
//  ReaderControls.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

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

struct ChapterEdgeRow: View {
    enum Edge { case previous, next }

    let edge: Edge
    let label: String
    let isArmed: Bool
    let onTrigger: () -> Void

    @State private var isVisible = false
    @State private var isTransitioning = false

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
        .onAppear { isVisible = isArmed }
        .onDisappear { isVisible = false }
        .onChange(of: isArmed) { armed in if !armed { isVisible = false } }
        .task(id: isVisible) {
            guard isVisible else {
                isTransitioning = false
                return
            }
            isTransitioning = true
            try? await Task.sleep(nanoseconds: 550_000_000)
            if !Task.isCancelled && isArmed { onTrigger() }
        }
        .accessibilityLabel(edge == .previous ? "Previous chapter, \(label)" : "Next chapter, \(label)")
    }
}

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
