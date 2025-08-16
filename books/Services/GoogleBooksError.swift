import Foundation

enum GoogleBooksError: LocalizedError {
    case invalidAPIKey
    case apiKeyMissing
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case quotaExceeded
    case invalidRequest(String)
    case networkError(Error)
    case decodingError(Error)
    case httpError(statusCode: Int, message: String?)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .apiKeyMissing:
            return "API key not found. Please configure your Google Books API key."
        case .rateLimitExceeded(let retryAfter):
            if let retry = retryAfter {
                return "Rate limit exceeded. Try again in \(Int(retry)) seconds."
            }
            return "Rate limit exceeded. Please try again later."
        case .quotaExceeded:
            return "API quota exceeded for today."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Unable to process server response."
        case .httpError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAPIKey, .apiKeyMissing:
            return "Check Config.xcconfig file and ensure API key is valid."
        case .rateLimitExceeded:
            return "Wait a moment before making another request."
        case .quotaExceeded:
            return "Daily quota reached. Try again tomorrow or upgrade your API plan."
        case .networkError:
            return "Check your internet connection and try again."
        default:
            return nil
        }
    }
}

