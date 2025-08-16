import Foundation
import os.log

final class GoogleBooksDiagnostics: @unchecked Sendable {
    static let shared = GoogleBooksDiagnostics()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GoogleBooksApp",
                                category: "GoogleBooksAPI")
    
    private var requestHistory: [RequestLog] = []
    private let maxHistorySize = 50
    
    struct RequestLog {
        let id = UUID()
        let timestamp = Date()
        let endpoint: String
        let parameters: [String: Any]
        let statusCode: Int?
        let responseTime: TimeInterval
        let error: Error?
        let responseSize: Int?
    }
    
    @discardableResult
    func logRequest(endpoint: String, parameters: [String: Any]) -> UUID {
        let requestId = UUID()
        logger.info("📤 Request [\(requestId)]: \(endpoint)")
        logger.debug("Parameters: \(parameters)")
        return requestId
    }
    
    func logResponse(requestId: UUID, statusCode: Int, responseTime: TimeInterval, dataSize: Int?) {
        logger.info("📥 Response [\(requestId)]: Status \(statusCode) in \(String(format: "%.2f", responseTime))s")
        if let size = dataSize {
            logger.debug("Response size: \(size) bytes")
        }
    }
    
    func logError(requestId: UUID, error: Error, context: String) {
        logger.error("❌ Error [\(requestId)]: \(error.localizedDescription)")
        logger.debug("Context: \(context)")
    }
    
    func logAPIKeyStatus() {
        if let _ = Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String {
            logger.info("✅ API key found in configuration")
        } else {
            logger.error("⚠️ API key missing from configuration")
        }
    }
    
    func exportDiagnostics() -> String {
        var report = "Google Books API Diagnostics Report\n"
        report += "Generated: \(Date())\n\n"
        report += "Recent Requests:\n"
        
        for log in requestHistory.suffix(20) {
            report += "\n[\(log.timestamp)] \(log.endpoint)\n"
            report += "  Status: \(log.statusCode ?? 0)\n"
            report += "  Response Time: \(String(format: "%.2f", log.responseTime))s\n"
            if let error = log.error {
                report += "  Error: \(error.localizedDescription)\n"
            }
        }
        
        return report
    }
}
