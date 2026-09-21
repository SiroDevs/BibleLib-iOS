//
//  SplashView.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel: SplashViewModel = DiContainer.shared.resolve(SplashViewModel.self)
    @State private var navigateToNextScreen = false
    @State private var readerReady = false

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
                readerReady = viewModel.prefsRepo.hasCompletedSelection
                navigateToNextScreen = true
            }
        }
        .animation(.easeInOut, value: navigateToNextScreen)
        .animation(.easeInOut, value: readerReady)
    }

    @ViewBuilder
    private var destinationView: some View {
        if readerReady {
            NavigationStack {
                ReaderView()
            }
            .environment(\.restartApp, { readerReady = false })
        } else {
            SelectionView(onFinished: { _ in readerReady = true })
        }
    }
}

struct SplashContent: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image(.mainIcon)
                .resizable()
                .frame(width: 200, height: 200)

            Text(AppConstants.appTitle)
                .font(.system(size: 50, weight: .bold))
                .kerning(5)
                .foregroundColor(.primary1)
                .padding(.top, 5)
            
            Spacer()
            
            Divider()
                .frame(height: 1)
                .padding(.horizontal, 100)
                .background(.onPrimaryContainer)

            Text(AppConstants.appCredits)
                .font(.system(size: 16))
                .foregroundColor(.primary1)
            .padding(.top, 20)

            Spacer().frame(height: 20)
        }.padding()
    }
}
#Preview {
    SplashView()
}
