import Foundation

/// Application configuration manager
enum Config {
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
