//
//  UiState.swift
//  BibleLib
//
//  Carried over unchanged from SwahiLib's footprint.
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
}
