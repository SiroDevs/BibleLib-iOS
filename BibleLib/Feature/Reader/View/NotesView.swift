//
//  NotesView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI

struct NotesView: View {
    let request: NotesRequest

    @StateObject private var viewModel = DiContainer.shared.resolve(NotesViewModel.self)
    @FocusState private var isEditing: Bool

    var body: some View {
        Form {
            Section {
                Text(request.verseText)
                    .font(.body)
                    .italic()
            } header: {
                Text(request.title)
            }

            Section("Your notes") {
                TextEditor(text: $viewModel.noteText)
                    .focused($isEditing)
                    .frame(minHeight: 180)
                    .overlay(alignment: .topLeading) {
                        if viewModel.noteText.isEmpty {
                            Text("Write your thoughts on this verse...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: viewModel.noteText) { _ in viewModel.noteTextChanged() }
            }
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    viewModel.save()
                    isEditing = false
                }
                .fontWeight(.semibold)
                .disabled(viewModel.isSaved)
            }
        }
        .onAppear { viewModel.initialize(request) }
        // Leaving with unsaved text saves it rather than silently dropping it.
        .onDisappear {
            if !viewModel.isSaved { viewModel.save() }
        }
    }
}
