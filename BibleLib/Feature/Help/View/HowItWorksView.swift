//
//  HowItWorksView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct HowItWorksView: View {
    private struct Topic: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let description: String
    }

    private let topics: [Topic] = [
        Topic(
            title: "Selecting Bibles",
            systemImage: "checklist",
            description: "When you first open BibleLib, you'll be presented with a list of available Bible translations. Tap on any translation to select or deselect it. You can choose one or more translations to download and read side by side. Once you're happy with your selection, tap Continue to start reading. You can always add or remove translations later from Manage Bibles in the menu."
        ),
        Topic(
            title: "Reading & Navigating",
            systemImage: "book",
            description: "Use the book selector to jump between the Old and New Testaments and pick any book or chapter. Swipe right on a verse to bookmark it, or left to add a note. Long press a verse to select multiple verses at once, then choose a highlight colour or share your selection. If you've enabled more than one translation, you can read them side by side in the same view."
        ),
        Topic(
            title: "Searching",
            systemImage: "magnifyingglass",
            description: "Tap the search icon to look up any word or phrase across your downloaded translations. Results update as you type and show the verse in context. Tap any result to open it directly in the reader at that verse."
        ),
        Topic(
            title: "Bookmarks & Notes",
            systemImage: "bookmark",
            description: "Every verse you bookmark or add a note to is collected under Bookmarks & Notes. Tap any entry to jump straight back to that verse in the reader, or open a note to edit it."
        ),
        Topic(
            title: "Scripture Lists",
            systemImage: "list.bullet.rectangle",
            description: "The Scripture Opener lets you build a queue of specific books, chapters, and verses — handy for sermon prep or study plans. Select multiple references, then save them as a Scripture List so you can revisit or present the same set of passages again later."
        ),
        Topic(
            title: "Your History",
            systemImage: "clock.arrow.circlepath",
            description: "BibleLib keeps track of the verses and chapters you've read so you can pick up right where you left off. Open History from the menu to see a timeline of your recent reading and tap any entry to return to it."
        ),
    ]

    @State private var expanded: Set<UUID> = []

    var body: some View {
        List {
            Section {
                ForEach(topics) { topic in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expanded.contains(topic.id) },
                            set: { isOn in
                                if isOn { expanded.insert(topic.id) } else { expanded.remove(topic.id) }
                            }
                        )
                    ) {
                        Text(topic.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } label: {
                        Label(topic.title, systemImage: topic.systemImage)
                            .font(.headline)
                    }
                }
            } header: {
                Text("Learn how to get the most out of BibleLib")
                    .textCase(nil)
            }
        }
        .navigationTitle("How It Works")
        .navigationBarTitleDisplayMode(.inline)
    }
}
