//
//  SettingsView.swift
//  BibleLib
//
//  Created by @sirodevs on 21/09/2026.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("Preferences") {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }
                NavigationLink {
                    ReadingSettingsView()
                } label: {
                    Label("Reading", systemImage: "textformat.size")
                }
            }

            Section("Bibles") {
                NavigationLink {
                    BiblesView()
                } label: {
                    Label("Manage Bibles", systemImage: "books.vertical")
                }
            }

            Section("Data") {
                NavigationLink {
                    DataSettingsView()
                } label: {
                    Label("App Data", systemImage: "externaldrive")
                }
            }

            Section("Help") {
                NavigationLink {
                    HelpView()
                } label: {
                    Label("Help & Feedback", systemImage: "questionmark.circle")
                }
                NavigationLink {
                    HowItWorksView()
                } label: {
                    Label("How It Works", systemImage: "lightbulb")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
