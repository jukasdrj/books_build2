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
    
    /// Check if running in iOS Simulator (haptics don't work properly)
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    private init() {
        // Only prepare generators on physical devices
        if !isSimulator {
            prepareGenerators()
        }
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
        guard !isSimulator else { return }
        selection.selectionChanged()
    }
    
    /// Triggered when rating is completed/confirmed
    func ratingCompleted() {
        guard !isSimulator else { return }
        impactMedium.impactOccurred()
    }
    
    /// Triggered when book is marked as read (success feedback)
    func bookMarkedAsRead() {
        guard !isSimulator else { return }
        notification.notificationOccurred(.success)
    }
    
    /// Triggered at start of swipe gesture
    func swipeToRate() {
        guard !isSimulator else { return }
        impactLight.impactOccurred()
    }
    
    /// Triggered when long press gesture starts
    func longPressStarted() {
        guard !isSimulator else { return }
        impactLight.impactOccurred()
    }
    
    /// Triggered for general UI interactions
    func lightImpact() {
        guard !isSimulator else { return }
        impactLight.impactOccurred()
    }
    
    /// Triggered for medium emphasis interactions
    func mediumImpact() {
        guard !isSimulator else { return }
        impactMedium.impactOccurred()
    }
    
    /// Triggered for heavy emphasis interactions
    func heavyImpact() {
        guard !isSimulator else { return }
        impactHeavy.impactOccurred()
    }
    
    /// Generic success feedback
    func success() {
        guard !isSimulator else { return }
        notification.notificationOccurred(.success)
    }
    
    /// Generic warning feedback
    func warning() {
        guard !isSimulator else { return }
        notification.notificationOccurred(.warning)
    }
    
    /// Generic error feedback
    func error() {
        guard !isSimulator else { return }
        notification.notificationOccurred(.error)
    }
    
    // MARK: - Async Wrappers for SwiftUI
    
    /// Async wrapper for impact feedback
    func impact() async {
        guard !isSimulator else { return }
        impactLight.impactOccurred()
    }
    
    /// Async wrapper for heavy impact feedback
    func impactHeavy() async {
        guard !isSimulator else { return }
        impactHeavy.impactOccurred()
    }
    
    /// Async wrapper for destructive action feedback
    func destructiveAction() async {
        guard !isSimulator else { return }
        impactHeavy.impactOccurred()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        notification.notificationOccurred(.warning)
    }
    
    /// Async wrapper for success feedback
    func success() async {
        guard !isSimulator else { return }
        notification.notificationOccurred(.success)
    }
    
    /// Async wrapper for warning feedback
    func warning() async {
        guard !isSimulator else { return }
        notification.notificationOccurred(.warning)
    }
    
    /// Async wrapper for error feedback
    func error() async {
        guard !isSimulator else { return }
        notification.notificationOccurred(.error)
    }
}