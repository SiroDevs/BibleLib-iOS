//
//  AppButtonStyle.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

enum AppButtonKind {
    case filled
    case outlined
    case text
}

struct AppButtonStyle: ButtonStyle {
    var kind: AppButtonKind = .filled
    /// nil = fully rounded (Material's default button shape).
    var cornerRadius: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        AppButtonBody(configuration: configuration, kind: kind, cornerRadius: cornerRadius)
    }
}

private struct AppButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let kind: AppButtonKind
    let cornerRadius: CGFloat?

    @Environment(\.isEnabled) private var isEnabled

    private static let height: CGFloat = 40

    private var contentColor: Color {
        guard isEnabled else { return AppColors.onSurface.opacity(0.38) }
        switch kind {
        case .filled: return AppColors.onPrimary
        case .outlined, .text: return AppColors.primary
        }
    }

    private var containerColor: Color {
        switch kind {
        case .filled: return isEnabled ? AppColors.primary : AppColors.onSurface.opacity(0.12)
        case .outlined, .text: return .clear
        }
    }

    private var borderColor: Color {
        isEnabled ? AppColors.outline : AppColors.onSurface.opacity(0.12)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius ?? Self.height / 2)

        configuration.label
            .textStyle(.labelLarge)
            .foregroundStyle(contentColor)
            .padding(.horizontal, kind == .text ? 12 : 24)
            .frame(minHeight: Self.height)
            .background(shape.fill(containerColor))
            .overlay {
                if kind == .outlined {
                    shape.strokeBorder(borderColor, lineWidth: 1)
                }
            }
            .overlay(shape.fill(contentColor.opacity(configuration.isPressed ? 0.12 : 0)))
            .contentShape(shape)
    }
}

extension ButtonStyle where Self == AppButtonStyle {
    static var appFilled: AppButtonStyle { AppButtonStyle(kind: .filled) }
    static var appOutlined: AppButtonStyle { AppButtonStyle(kind: .outlined) }
    static var appText: AppButtonStyle { AppButtonStyle(kind: .text) }
}
