//
//  UiState.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
//

enum UiState: Equatable {
    case idle
    case loading(String? = nil)
    case saving(String? = nil)
    case synced
    case fetched
    case saved
    case loaded
    case error(String)
    case saveFailed(message: String, progress: Double)
}
