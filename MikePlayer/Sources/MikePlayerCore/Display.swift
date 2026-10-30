import Foundation

public enum Display {
    public static let version = "2.0.0"
    public static let progressWidth = 40
    public static let hint = "c: pause/play   v: next   z: previous   j: jump   t: set timer   q: quit"

    public static func progressBar(elapsed: Double, length: Double, width: Int = progressWidth) -> String {
        let pct = length > 0 ? min(max(elapsed / length, 0), 1) : 0
        let filled = Int((pct * Double(width)).rounded())
        return "[" + String(repeating: "#", count: filled) + String(repeating: "-", count: width - filled) + "]"
    }

    public static func duration(_ length: Double, elapsed: Double? = nil) -> String {
        let l = Int(length)
        var result = String(format: "%02d:%02d", (l % 3600) / 60, l % 60)

        if l >= 3600 {
            result = String(format: "%02d:", l / 3600) + result
        }

        guard let elapsed else { return result }

        let e = Int(elapsed)
        return String(format: "%02d:%02d [", e / 60, e % 60) + result + "]"
    }
}
