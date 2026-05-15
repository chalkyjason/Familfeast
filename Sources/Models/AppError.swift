import Foundation

/// Unified error type for the application
enum AppError: LocalizedError, Identifiable {
    case database(Error)
    case network(Error)
    case cloudKit(CloudKitError)
    case auth(String)
    case validation(String)
    case unknown(Error)

    var id: String {
        switch self {
        case .database: return "db"
        case .network: return "network"
        case .cloudKit: return "ck"
        case .auth: return "auth"
        case .validation: return "validation"
        case .unknown: return "unknown"
        }
    }

    var errorDescription: String? {
        switch self {
        case .database(let error):
            return "Database Error: \(error.localizedDescription)"
        case .network(let error):
            return "Connection Error: \(error.localizedDescription)"
        case .cloudKit(let error):
            return error.localizedDescription
        case .auth(let message):
            return "Authentication Error: \(message)"
        case .validation(let message):
            return message
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .network:
            return "Please check your internet connection and try again."
        case .cloudKit(.notAuthenticated):
            return "Please sign in to iCloud in your device settings."
        default:
            return "If the problem persists, please contact support."
        }
    }
}
