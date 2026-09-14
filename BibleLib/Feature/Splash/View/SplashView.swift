//
//  SplashView.swift
//  BibleLib
//

import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel: SplashViewModel = DiContainer.shared.resolve(SplashViewModel.self)
    @State private var navigateToNextScreen = false

    var body: some View {
        Group {
            if navigateToNextScreen {
                destinationView
            } else {
                SplashContent()
                    .onAppear { viewModel.initialize() }
            }
        }
        .onReceive(viewModel.$isInitialized) { initialized in
            guard initialized else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                navigateToNextScreen = true
            }
        }
        .animation(.easeInOut, value: navigateToNextScreen)
    }

    @ViewBuilder
    private var destinationView: some View {
        if viewModel.prefsRepo.hasCompletedSelection, let abbr = viewModel.prefsRepo.primaryBibleAbbr {
            NavigationStack {
                ReaderView(bibleAbbr: abbr)
            }
        } else {
            SelectionView()
        }
    }
}

private struct SplashContent: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "book.closed.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundColor(.accentColor)
            Text(AppConstants.appTitle)
                .font(.system(size: 40, weight: .bold))
            Text(AppConstants.appTagline)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SplashView()
}
