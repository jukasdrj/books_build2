//
//  PageInputView.swift
//  books
//
//  Created by Justin Gardner on 7/26/25.
//

import SwiftUI

struct PageInputView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    let onSave: () -> Void
    
    @State private var currentPageText: String
    @State private var totalPagesText: String
    
    init(currentPage: Binding<Int>, totalPages: Binding<Int>, onSave: @escaping () -> Void) {
        self._currentPage = currentPage
        self._totalPages = totalPages
        self.onSave = onSave
        self._currentPageText = State(initialValue: "\(currentPage.wrappedValue)")
        self._totalPagesText = State(initialValue: totalPages.wrappedValue > 0 ? "\(totalPages.wrappedValue)" : "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Progress") {
                    HStack {
                        Text("Current Page")
                            .labelMedium()
                        Spacer()
                        TextField("0", text: $currentPageText)
                            .frame(width: 80)
                            .bodyMedium()
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Total Pages")
                            .labelMedium()
                        Spacer()
                        TextField("0", text: $totalPagesText)
                            .frame(width: 80)
                            .bodyMedium()
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let current = Int(currentPageText), let total = Int(totalPagesText), total > 0 {
                    Section("Progress") {
                        VStack(spacing: Theme.Spacing.sm) {
                            let progress = min(max(Double(current) / Double(total), 0.0), 1.0) // Clamp between 0.0 and 1.0
                            
                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                            
                            Text("\(Int(progress * 100))% complete")
                                .labelSmall()
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Update Progress")
            .keyboardAvoidingLayout()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProgress()
                        dismiss()
                    }
                    .disabled(!isValidInput)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                      to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        guard let current = Int(currentPageText),
              let total = Int(totalPagesText) else {
            return false
        }
        return current >= 0 && total >= 0 && current <= total
    }
    
    private func saveProgress() {
        if let current = Int(currentPageText) {
            currentPage = current
        }
        if let total = Int(totalPagesText) {
            totalPages = total
        }
        onSave()
    }
}

#Preview {
    PageInputView(
        currentPage: .constant(150),
        totalPages: .constant(300),
        onSave: {}
    )
}