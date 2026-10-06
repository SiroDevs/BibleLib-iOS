//
//  ReaderControls.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

final class ScrollViewLocatorView: UIView {
    private weak var cached: UIScrollView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func findScrollView() -> UIScrollView? {
        if let cached, cached.window != nil { return cached }
        cached = nil

        var ancestor = superview
        var depth = 0
        while let current = ancestor, depth < 8 {
            if let found = Self.firstScrollView(in: current) {
                cached = found
                return found
            }
            ancestor = current.superview
            depth += 1
        }
        return nil
    }

    private static func firstScrollView(in root: UIView) -> UIScrollView? {
        var queue = [root]
        var index = 0
        while index < queue.count {
            let view = queue[index]
            index += 1
            if let scrollView = view as? UIScrollView { return scrollView }
            queue.append(contentsOf: view.subviews)
        }
        return nil
    }
}

struct ScrollViewLocator: UIViewRepresentable {
    let controller: AutoScrollController

    func makeUIView(context: Context) -> ScrollViewLocatorView {
        let view = ScrollViewLocatorView()
        controller.locator = view
        return view
    }

    func updateUIView(_ uiView: ScrollViewLocatorView, context: Context) {
        controller.locator = uiView
    }
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
                .padding(.horizontal, 16)
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
