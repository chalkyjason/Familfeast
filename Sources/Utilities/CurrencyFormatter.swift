import Foundation

extension Int {
    /// Formats cents as a dollar string, e.g. 1500 → "$15.00"
    var asDollarString: String {
        "$\(String(format: "%.2f", Double(self) / 100.0))"
    }
}
