//
//  EmptyState.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

struct EmptyState: View {
    var message: String = "Nothing here yet"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(.secondary)

            Text(message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyState()
}
