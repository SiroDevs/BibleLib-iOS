//
//  Bible.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

import Foundation

struct Bible: Identifiable, Codable, Hashable {
    var id: String { abbreviation }
    let abbreviation: String
    let name: String
    let description: String
    let languageName: String
    let scriptDirection: String
    var sortOrder: Int = 0
    var isDownloaded: Bool = false
    var countryName: String = ""
    var downloadProgress: Double = 0
    var downloadFailed: Bool = false
    /// Remote folder for this Bible's content; blank falls back to the abbreviation.
    var path: String = ""
}
