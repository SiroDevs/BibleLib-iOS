//
//  AutoScroll.swift
//  BibleLib
//
//  Created by @sirodevs on 06/10/2026.
//

import SwiftUI

final class AutoScrollController: ObservableObject {
    static let minSpeed = AutoScrollSpeed.minimum
    static let maxSpeed = AutoScrollSpeed.maximum
    static let step = AutoScrollSpeed.step
    static let defaultSpeed = AutoScrollSpeed.standard

    static let pointsPerSecondAtOneX: CGFloat = 40

    @Published var isRunning = false {
        didSet {
            guard oldValue != isRunning else { return }
            isRunning ? startDisplayLink() : stopDisplayLink()
        }
    }
    
    @Published var speed: Double {
        didSet {
            guard speed != oldValue else { return }
            UserDefaults.standard.set(speed, forKey: PrefConstants.autoScrollSpeed)
        }
    }

    weak var locator: ScrollViewLocatorView?
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

        if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating
            || lastApplied == nil || abs(current - (lastApplied ?? current)) > 1 {
            position = current
            lastApplied = current
            return
        }

        let inset = scrollView.adjustedContentInset
        let minY = -inset.top
        let maxY = max(minY, scrollView.contentSize.height + inset.bottom - scrollView.bounds.height)

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

private final class DisplayLinkProxy: NSObject {
    private weak var target: AutoScrollController?

    init(_ target: AutoScrollController) { self.target = target }

    @objc func fire(_ link: CADisplayLink) {
        guard let target else { link.invalidate(); return }
        target.tick(link)
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
