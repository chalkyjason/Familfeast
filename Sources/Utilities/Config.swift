import Foundation
import OSLog

/// Application configuration manager
enum Config {
    /// Fetch OpenAI API Key from environment or Info.plist
    static var openAIKey: String {
        // 1. Check process environment (useful for testing/CI)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 2. Check Info.plist (standard for released apps)
        if let plistKey = Bundle.main.infoDictionary?["OpenAIKey"] as? String, !plistKey.isEmpty {
            return plistKey
        }
        
        Logger.app.warning("OpenAI API Key not found in environment or Info.plist")
        return ""
    }
    
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    static var cloudKitContainerIdentifier: String {
        return "iCloud.com.mealmeld.app"
    }

}
