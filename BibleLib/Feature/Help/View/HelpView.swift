//
//  HelpView.swift
//  BibleLib
//
//  Created by @sirodevs on 20/09/2026.
//

import SwiftUI
import PhotosUI
import MessageUI

struct HelpView: View {
    private static let supportEmail = "futuristicken@gmail.com"
    private static let maxAttachments = 5

    @State private var title = ""
    @State private var details = ""
    @State private var pickedItems: [PhotosPickerItem] = []
    @State private var attachments: [Data] = []
    @State private var showValidation = false
    @State private var showMailComposer = false
    @State private var showNoMailAlert = false

    var body: some View {
        Form {
            Section {
                Text("If you are experiencing any issues or have suggestions, you can contact us or get help. Fill in the form below and we'll get back to you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("We're here to help!").textCase(nil).font(.headline)
            }

            Section {
                TextField("Brief summary of your issue or suggestion", text: $title)
                if showValidation && trimmedTitle.isEmpty {
                    Text("Title is required").font(.caption).foregroundStyle(.red)
                }
            } header: {
                Text("Title *")
            }

            Section {
                TextEditor(text: $details)
                    .frame(minHeight: 140)
                    .overlay(alignment: .topLeading) {
                        if details.isEmpty {
                            Text("Describe the issue or your suggestion in detail...")
                                .foregroundStyle(Color(.tertiaryLabel))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                if showValidation && trimmedDetails.isEmpty {
                    Text("Description is required").font(.caption).foregroundStyle(.red)
                }
            } header: {
                Text("Description *")
            }

            Section {
                PhotosPicker(
                    selection: $pickedItems,
                    maxSelectionCount: Self.maxAttachments,
                    matching: .images
                ) {
                    Label(attachments.isEmpty ? "Tap to attach images" : "Change images", systemImage: "photo.on.rectangle.angled")
                }

                if !attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(attachments.indices, id: \.self) { index in
                                if let image = UIImage(data: attachments[index]) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Screenshots or Recordings (optional)")
            } footer: {
                Text("Up to \(Self.maxAttachments) files")
            }

            Section {
                Button {
                    send()
                } label: {
                    Text("Contact Us").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Help & Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickedItems) { items in
            Task {
                var loaded: [Data] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) { loaded.append(data) }
                }
                attachments = loaded
            }
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                recipient: Self.supportEmail,
                subject: "BibleLib: \(trimmedTitle)",
                body: emailBody,
                attachments: attachments.enumerated().map { index, data in
                    (data: data, mimeType: "image/jpeg", fileName: "attachment_\(index + 1).jpg")
                },
                onFinish: { showMailComposer = false }
            )
        }
        .alert("Can't send email", isPresented: $showNoMailAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Set up a Mail account on this device, or write to \(Self.supportEmail).")
        }
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedDetails: String { details.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var emailBody: String {
        let device = UIDevice.current
        return """
        Title: \(trimmedTitle)
        Description:
        \(trimmedDetails)

        ---
        Device Info:
        Model: \(device.model)
        iOS: \(device.systemVersion)
        """
    }

    private func send() {
        showValidation = true
        guard !trimmedTitle.isEmpty, !trimmedDetails.isEmpty else { return }

        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else if let url = mailtoURL() {
            UIApplication.shared.open(url) { success in
                if !success { showNoMailAlert = true }
            }
        } else {
            showNoMailAlert = true
        }
    }

    private func mailtoURL() -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "BibleLib: \(trimmedTitle)"),
            URLQueryItem(name: "body", value: emailBody),
        ]
        return components.url
    }
}
