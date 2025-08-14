#if DEBUG
import SwiftUI

struct DebugConsoleView: View {
    @State private var diagnosticReport = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(diagnosticReport)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("API Diagnostics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        diagnosticReport = GoogleBooksDiagnostics.shared.exportDiagnostics()
                    }
                }
            }
        }
        .onAppear {
            diagnosticReport = GoogleBooksDiagnostics.shared.exportDiagnostics()
        }
    }
}
#endif

