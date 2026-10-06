//
//  ReaderControls.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

final class AutoScrollController: ObservableObject {
    static let minSpeed = AutoScrollSpeed.minimum
    static let maxSpeed = AutoScrollSpeed.maximum
    static let step = AutoScrollSpeed.step
    static let defaultSpeed = AutoScrollSpeed.standard

    /// Scroll distance in points per second at 1x. At 0.25x this is 10 pt/s,
    /// i.e. roughly half a pixel per frame on a 3x display, so the list creeps
    /// one pixel at a time instead of stepping verse by verse.
    static let pointsPerSecondAtOneX: CGFloat = 40

    @Published var isRunning = false {
        didSet {
            guard oldValue != isRunning else { return }
            isRunning ? startDisplayLink() : stopDisplayLink()
        }
    }
    /// Persisted, and kept in sync with the Reading / Quick Settings sliders.
    @Published var speed: Double {
        didSet {
            guard speed != oldValue else { return }
            UserDefaults.standard.set(speed, forKey: PrefConstants.autoScrollSpeed)
        }
    }

    /// Set by `ScrollViewLocator`; used to find the list's underlying UIScrollView.
    weak var locator: ScrollViewLocatorView?
    /// Called every frame while the list is pinned at its bottom edge.
    var onReachedEnd: (() -> Void)?

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var position: CGFloat = 0
    private var lastApplied: CGFloat?

    private var defaultsObserver: NSObjectProtocol?

    init() {
        speed = Self.storedSpeed()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let stored = Self.storedSpeed()
            if stored != self.speed { self.speed = stored }
        }
    }

    deinit {
        displayLink?.invalidate()
        if let defaultsObserver { NotificationCenter.default.removeObserver(defaultsObserver) }
    }

    private static func storedSpeed() -> Double {
        let stored = UserDefaults.standard.object(forKey: PrefConstants.autoScrollSpeed) as? Double
        return min(max(stored ?? defaultSpeed, minSpeed), maxSpeed)
    }

    func toggle() { isRunning.toggle() }
    func speedUp() { speed = min(speed + Self.step, Self.maxSpeed) }
    func speedDown() { speed = max(speed - Self.step, Self.minSpeed) }
    func resetSpeed() { speed = Self.defaultSpeed }

    var canSpeedUp: Bool { speed < Self.maxSpeed }
    var canSpeedDown: Bool { speed > Self.minSpeed }

    var speedLabel: String { AutoScrollSpeed.label(speed) }

    // MARK: - Pixel-accurate scrolling

    private func startDisplayLink() {
        stopDisplayLink()
        lastTimestamp = 0
        lastApplied = nil
        let link = CADisplayLink(target: DisplayLinkProxy(self), selector: #selector(DisplayLinkProxy.fire(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        lastApplied = nil
    }

    fileprivate func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = lastTimestamp == 0 ? 0 : min(now - lastTimestamp, 0.1)
        lastTimestamp = now

        guard let scrollView = locator?.findScrollView(), scrollView.window != nil else {
            lastApplied = nil
            return
        }

        let current = scrollView.contentOffset.y

        // The user is touching the list, or something else moved it
        // (chapter change, scroll-to-top, jump to verse): follow it, don't fight it.
        if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating
            || lastApplied == nil || abs(current - (lastApplied ?? current)) > 1 {
            position = current
            lastApplied = current
            return
        }

        let inset = scrollView.adjustedContentInset
        let minY = -inset.top
        let maxY = max(minY, scrollView.contentSize.height + inset.bottom - scrollView.bounds.height)

        // Accumulate in sub-point precision, then snap to a physical pixel so
        // every applied step is a whole pixel (UIKit would otherwise round it away).
        position += CGFloat(speed) * Self.pointsPerSecondAtOneX * CGFloat(dt)
        let reachedEnd = position >= maxY
        if reachedEnd { position = maxY }

        let scale = max(scrollView.traitCollection.displayScale, 1)
        let snapped = (position * scale).rounded() / scale
        if snapped != current {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: snapped)
        }
        lastApplied = snapped

        if reachedEnd { onReachedEnd?() }
    }
}

/// CADisplayLink retains its target; this weak proxy avoids a retain cycle.
private final class DisplayLinkProxy: NSObject {
    private weak var target: AutoScrollController?

    init(_ target: AutoScrollController) { self.target = target }

    @objc func fire(_ link: CADisplayLink) {
        guard let target else { link.invalidate(); return }
        target.tick(link)
    }
}

/// Invisible view dropped behind the List so we can reach its UIScrollView.
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
            .disabled(!controller.canSpeedDown)
            .accessibilityLabel("Slow down auto scroll")

            Divider().frame(height: 20)

            Button(action: controller.resetSpeed) {
                Text(controller.speedLabel)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 56, minHeight: 40)
            }
            .accessibilityLabel("Auto scroll speed \(controller.speedLabel). Tap to reset.")

            Divider().frame(height: 20)

            Button(action: controller.speedUp) {
                Image(systemName: "plus")
                    .frame(width: 44, height: 40)
            }
            .disabled(!controller.canSpeedUp)
            .accessibilityLabel("Speed up auto scroll")
        }
        .font(.body.weight(.semibold))
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

/// Slider section shared by Reading settings and the reader's Quick Settings.
struct AutoScrollSpeedSection: View {
    @AppStorage(PrefConstants.autoScrollSpeed) private var speed = AutoScrollSpeed.standard

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "tortoise")
                Slider(value: $speed, in: AutoScrollSpeed.minimum...AutoScrollSpeed.maximum, step: AutoScrollSpeed.step)
                Image(systemName: "hare")
            }
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Auto scroll speed")
            .accessibilityValue(AutoScrollSpeed.label(speed))
        } header: {
            Text("Auto scroll speed: \(AutoScrollSpeed.label(speed))")
        } footer: {
            Text("Default is \(AutoScrollSpeed.label(AutoScrollSpeed.standard)). You can also adjust it with − and + while scrolling.")
        }
    }
}
