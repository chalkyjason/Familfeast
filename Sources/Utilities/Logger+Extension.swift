import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs for general app-level events
    static let app = Logger(subsystem: subsystem, category: "app")
    
    /// Logs for database/SwiftData operations
    static let database = Logger(subsystem: subsystem, category: "database")
    
    /// Logs for CloudKit synchronization
    static let cloudKit = Logger(subsystem: subsystem, category: "cloudkit")
    
    /// Logs for AI service interactions
    static let ai = Logger(subsystem: subsystem, category: "ai")
    
    /// Logs for authentication events
    static let auth = Logger(subsystem: subsystem, category: "auth")
    
    /// Logs for UI-related events
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
