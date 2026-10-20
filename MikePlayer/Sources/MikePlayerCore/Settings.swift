import Foundation

public struct Settings {
    public static let defaultVolume = 0.1
    public static let playlistEnding = ".mpl"

    public var shuffle = false
    public var overwrite = false
    public var random = 0
    public var minutes = 0
    public var searchTerms: [String] = []
    public let volume: Double
    public let musicDir: String
    public let settingsDir: String
    public let playlistPath: String

    public init(arguments: [String], home: String = NSHomeDirectory(), defaults: UserDefaults = .standard) {
        var args = arguments[...]
        var volumeOption: Double?
        var directoryOption: String?
        var playlistOption: String?

        while let arg = args.popFirst() {
            switch arg {
            case "-s", "--shuffle": shuffle = true
            case "-o", "--overwrite": overwrite = true
            case "-r", "--random": random = Int(args.popFirst() ?? "") ?? 0
            case "-v", "--volume": volumeOption = Double(args.popFirst() ?? "")
            case "-p", "--playlist": playlistOption = args.popFirst()
            case "-d", "--directory": directoryOption = args.popFirst()
            case "-t", "--time": minutes = Int(args.popFirst() ?? "") ?? 0
            case "-f", "--fullscreen", "-l", "--list", "-x", "--debug": break
            default:
                if arg.hasPrefix("-NS") || arg.hasPrefix("-Apple") {
                    _ = args.popFirst()
                } else if !arg.hasPrefix("-") {
                    searchTerms.append(arg)
                }
            }
        }

        if let volumeOption { defaults.set(volumeOption, forKey: "volume") }
        if let directoryOption { defaults.set(directoryOption, forKey: "directory") }

        volume = volumeOption ?? defaults.object(forKey: "volume") as? Double ?? Self.defaultVolume
        musicDir = directoryOption ?? defaults.string(forKey: "directory") ?? (home as NSString).appendingPathComponent("Music")
        settingsDir = (home as NSString).appendingPathComponent(".mikeplayer")
        playlistPath = Self.playlistPath(option: playlistOption, random: random, settingsDir: settingsDir)
    }

    public var isRandom: Bool { random > 0 }

    public func prepare() throws {
        try FileManager.default.createDirectory(atPath: settingsDir, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: playlistPath), overwrite || isRandom {
            try FileManager.default.removeItem(atPath: playlistPath)
        }
    }

    static func playlistPath(option: String?, random: Int, settingsDir: String) -> String {
        let name: String

        if let option {
            if FileManager.default.fileExists(atPath: option) { return option }

            name = ((option as NSString).lastPathComponent as NSString).deletingPathExtension
        } else if random > 0 {
            name = "random_n\(random)"
        } else {
            name = "default"
        }

        return (settingsDir as NSString).appendingPathComponent(name + playlistEnding)
    }
}
