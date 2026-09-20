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
    @State private var finishedSelectionAbbr: String?
    @State private var appResetTick = 0

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
        .animation(.easeInOut, value: finishedSelectionAbbr)
        .onReceive(NotificationCenter.default.publisher(for: .appDataDidReset)) { _ in
            finishedSelectionAbbr = nil
            appResetTick += 1
        }
    }

    /// True once Bible selection has finished (this launch or an earlier one).
    private var showsReader: Bool {
        _ = appResetTick // re-evaluate after "Clear All Data"
        return finishedSelectionAbbr != nil || viewModel.prefsRepo.hasCompletedSelection
    }

    @ViewBuilder
    private var destinationView: some View {
        if showsReader {
            MainNavigationView()
        } else {
            SelectionView(onFinished: { finishedSelectionAbbr = $0 })
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
