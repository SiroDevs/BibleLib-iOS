//
//  RestartAppAction.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

private struct RestartAppKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var restartApp: () -> Void {
        get { self[RestartAppKey.self] }
        set { self[RestartAppKey.self] = newValue }
    }
}
