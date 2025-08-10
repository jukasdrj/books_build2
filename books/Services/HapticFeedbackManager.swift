//
//  HapticFeedbackManager.swift
//  books
//
//  Centralized haptic feedback system for rating gestures
//

import UIKit

@MainActor
class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for immediate use
        prepareGenerators()
    }
    
    /// Prepare all generators to reduce latency
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    /// Triggered when user changes star rating
    func ratingChanged() {
        selection.selectionChanged()
    }
    
    /// Triggered when rating is completed/confirmed
    func ratingCompleted() {
        impactMedium.impactOccurred()
    }
    
    /// Triggered when book is marked as read (success feedback)
    func bookMarkedAsRead() {
        notification.notificationOccurred(.success)
    }
    
    /// Triggered at start of swipe gesture
    func swipeToRate() {
        impactLight.impactOccurred()
    }
    
    /// Triggered when long press gesture starts
    func longPressStarted() {
        impactLight.impactOccurred()
    }
    
    /// Triggered for general UI interactions
    func lightImpact() {
        impactLight.impactOccurred()
    }
    
    /// Triggered for medium emphasis interactions
    func mediumImpact() {
        impactMedium.impactOccurred()
    }
    
    /// Triggered for heavy emphasis interactions
    func heavyImpact() {
        impactHeavy.impactOccurred()
    }
    
    /// Generic success feedback
    func success() {
        notification.notificationOccurred(.success)
    }
    
    /// Generic warning feedback
    func warning() {
        notification.notificationOccurred(.warning)
    }
    
    /// Generic error feedback
    func error() {
        notification.notificationOccurred(.error)
    }
    
    // MARK: - Async Wrappers for SwiftUI
    
    /// Async wrapper for impact feedback
    func impact() async {
        impactLight.impactOccurred()
    }
    
    /// Async wrapper for heavy impact feedback
    func impactHeavy() async {
        impactHeavy.impactOccurred()
    }
    
    /// Async wrapper for destructive action feedback
    func destructiveAction() async {
        impactHeavy.impactOccurred()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        notification.notificationOccurred(.warning)
    }
    
    /// Async wrapper for success feedback
    func success() async {
        notification.notificationOccurred(.success)
    }
    
    /// Async wrapper for warning feedback
    func warning() async {
        notification.notificationOccurred(.warning)
    }
    
    /// Async wrapper for error feedback
    func error() async {
        notification.notificationOccurred(.error)
    }
}