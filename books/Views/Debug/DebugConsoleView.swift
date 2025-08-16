#if DEBUG
import SwiftUI

struct DebugConsoleView: View {
    @State private var diagnosticReport = ""
    
    var body: some View {
        NavigationView {
            List {
                // API Security Management
                Section("Security Management") {
                    NavigationLink(destination: APIKeyManagementView()) {
                        Label("API Key Management", systemImage: "key.fill")
                    }
                }
                
                // API Diagnostics Report
                Section("Diagnostics Report") {
                    VStack(alignment: .leading) {
                        Text(diagnosticReport)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Debug Console")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        // Use the view model's export to avoid direct dependency issues
                        diagnosticReport = BooksViewModel().exportDiagnostics()
                    }
                }
            }
        }
        .onAppear {
            diagnosticReport = BooksViewModel().exportDiagnostics()
        }
    }
}
#endif

